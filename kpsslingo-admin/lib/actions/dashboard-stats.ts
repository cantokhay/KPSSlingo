// lib/actions/dashboard-stats.ts
'use server'

import { createSupabaseServerClient } from '@/lib/supabase/server'

/** Son 7 günün soru üretim sayıları */
export async function getQuestionProductionTrend() {
  const supabase = await createSupabaseServerClient()
  
  // Son 7 günü hesapla
  const sevenDaysAgo = new Date()
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7)
  
  const { data, error } = await supabase
    .from('questions')
    .select('created_at')
    .gte('created_at', sevenDaysAgo.toISOString())
  
  if (error) return []

  // Günlere göre grupla
  const counts: Record<string, { dateObj: Date; label: string; count: number }> = {}
  data.forEach((q) => {
    const d = new Date(q.created_at)
    const label = d.toLocaleDateString('tr-TR', { day: '2-digit', month: '2-digit' })
    const key = d.toISOString().split('T')[0] // Sortable key: YYYY-MM-DD
    
    if (!counts[key]) {
      counts[key] = { dateObj: d, label, count: 0 }
    }
    counts[key].count++
  })

  // Tarihe göre büyükten küçüğe sırala (Yeni tarihler önce)
  return Object.values(counts)
    .sort((a, b) => b.dateObj.getTime() - a.dateObj.getTime())
    .map(item => ({ date: item.label, count: item.count }))
}

/** Konu (Topic) bazlı soru dağılımı */
export async function getTopicDistribution() {
  const supabase = await createSupabaseServerClient()
  
  const { data, error } = await supabase
    .from('questions')
    .select('lessons(topics(title))')
  
  if (error) return []

  const counts: Record<string, number> = {}
  data.forEach((q: any) => {
    const title = q.lessons?.topics?.title || 'Bilinmiyor'
    counts[title] = (counts[title] || 0) + 1
  })

  return Object.entries(counts).map(([name, value]) => ({ name, value }))
}

/** Kalite skor dağılımı */
export async function getScoreDistribution() {
  const supabase = await createSupabaseServerClient()
  
  const { data, error } = await supabase
    .from('questions')
    .select('ai_review_score')
    .not('ai_review_score', 'is', null)
  
  if (error) return []

  // Skor dilimi için tip tanımı
  interface ScoreBin {
    range: string;
    count: number;
    start: number;
    end: number;
  }

  // 0-5 arası tek blok, sonrası 0.5'lik aralıklar
  const bins: ScoreBin[] = []
  
  // İlk blok: 0-5.0
  bins.push({ range: '0-5.0', count: 0, start: 0, end: 5.0 })
  
  // 5.0'dan sonra 0.5'lik aralıklar (5.0-5.5, ..., 9.5-10.0)
  for (let i = 0; i < 10; i++) {
    const start = 5.0 + (i * 0.5)
    const end = start + 0.5
    bins.push({
      range: `${start.toFixed(1)}-${end.toFixed(1)}`,
      count: 0,
      start,
      end
    })
  }

  data.forEach((q) => {
    const score = q.ai_review_score || 0
    if (score < 5.0) {
      bins[0].count++
    } else {
      const binIndex = Math.min(Math.floor((score - 5.0) / 0.5) + 1, bins.length - 1)
      bins[binIndex].count++
    }
  })

  return bins.map(({ range, count }) => ({ range, count }))
}

/** Genel özet istatistikler */
export async function getGeneralStats() {
  const supabase = await createSupabaseServerClient()
  
  const [
    { count: totalQuestions },
    { count: draftCount },
    { count: publishedCount },
    { count: userCount }
  ] = await Promise.all([
    supabase.from('questions').select('*', { count: 'exact', head: true }),
    supabase.from('questions').select('*', { count: 'exact', head: true }).eq('status', 'draft'),
    supabase.from('questions').select('*', { count: 'exact', head: true }).eq('status', 'published'),
    supabase.from('user_profiles').select('*', { count: 'exact', head: true })
  ])

  return {
    totalQuestions:  totalQuestions  ?? 0,
    draftCount:      draftCount      ?? 0,
    publishedCount:  publishedCount  ?? 0,
    userCount:       userCount       ?? 0
  }
}
