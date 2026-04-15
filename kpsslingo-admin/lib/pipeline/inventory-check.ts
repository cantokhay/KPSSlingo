import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

// Use Service Role to bypass RLS for inventory check
const supabase = createClient(supabaseUrl, supabaseServiceKey)

export interface LessonInventoryItem {
  lesson_id: string
  lesson_title: string
  topic_title: string
  published_count: number
  needed_count: number        // Kaç soru üretilmeli
  priority: 'critical' | 'high' | 'normal'
  avg_correct_rate: number | null   // Kullanıcı doğru cevap oranı (0-1)
}

const DEFAULT_MIN_PUBLISHED_THRESHOLD = 30    // Bu altında kalırsa mutlaka üret
const DEFAULT_TARGET_PUBLISHED_COUNT  = 60    // İdeal hedef
const HIGH_ERROR_RATE_THRESHOLD = 0.40 // Hata oranı > %40 ise ekstra üretim

export async function getInventoryNeeds(config?: {
  minThreshold?: number,
  targetCount?: number
}): Promise<LessonInventoryItem[]> {
  const minThreshold = config?.minThreshold ?? DEFAULT_MIN_PUBLISHED_THRESHOLD
  const targetCount = config?.targetCount ?? DEFAULT_TARGET_PUBLISHED_COUNT
  // 1. Tüm yayınlanmış dersler ve soru sayılarını çek
  const { data: lessons, error: lessonsError } = await supabase
    .from('lessons')
    .select(`
      id, title,
      topics ( title ),
      questions ( count )
    `)
    .eq('status', 'published')
    .is('deleted_at', null)

  if (lessonsError) {
    console.error('Error fetching lessons inventory:', lessonsError)
    return []
  }

  // Supabase count aggregation might return an array of objects depending on the query
  // We need to ensure we correctly count questions with status='published'

  // 2. Her dersin kullanıcı hata oranını hesapla (son 7 gün)
  const { data: errorRates, error: rpcError } = await supabase.rpc('get_lesson_error_rates', {
    days_back: 7
  })

  if (rpcError) {
    console.error('Error calling get_lesson_error_rates:', rpcError)
  }

  const errorRateMap = new Map<string, number | null>(
    (errorRates ?? []).map((r: any) => [
      r.lesson_id,
      r.total_attempts > 0
        ? 1 - (Number(r.correct_answers) / Number(r.total_attempts))
        : null
    ])
  )

  const needs: LessonInventoryItem[] = []

  // Re-fetch question counts specifically for 'published' status
  // because the nested questions(count) above might not filter by status accurately in a simple select
  const { data: counts } = await supabase
    .from('questions')
    .select('lesson_id')
    .eq('status', 'published')
    .is('deleted_at', null)

  const questionCountMap = new Map<string, number>()
  counts?.forEach(q => {
    questionCountMap.set(q.lesson_id, (questionCountMap.get(q.lesson_id) || 0) + 1)
  })

  for (const lesson of lessons ?? []) {
    const publishedCount = questionCountMap.get(lesson.id) || 0
    const errorRate = errorRateMap.get(lesson.id) ?? null

    let neededCount = 0
    let priority: LessonInventoryItem['priority'] = 'normal'

    // Kural 1: Minimum eşiğin altında
    if (publishedCount < minThreshold) {
      neededCount = targetCount - publishedCount
      priority = publishedCount === 0 ? 'critical' : 'high'
    }

    // Kural 2: Hata oranı yüksek → ekstra soru
    if (errorRate !== null && errorRate > HIGH_ERROR_RATE_THRESHOLD) {
      const extra = Math.ceil((Number(errorRate) - HIGH_ERROR_RATE_THRESHOLD) * 20)
      neededCount = Math.max(neededCount, extra)
      if (priority === 'normal') priority = 'high'
    }

    if (neededCount > 0) {
      needs.push({
        lesson_id: lesson.id,
        lesson_title: lesson.title,
        topic_title: (lesson.topics as any)?.title ?? '',
        published_count: publishedCount,
        needed_count: Math.min(neededCount, 20), // Tek seferde max 20
        priority,
        avg_correct_rate: errorRate !== null ? 1 - errorRate : null,
      })
    }
  }

  // Priority -> Fewer questions -> Topic title (rotation)
  const priorityOrder = { critical: 0, high: 1, normal: 2 }
  return needs.sort((a, b) => {
    if (a.priority !== b.priority) return priorityOrder[a.priority] - priorityOrder[b.priority]
    if (a.published_count !== b.published_count) return a.published_count - b.published_count
    return a.topic_title.localeCompare(b.topic_title)
  })
}
