// lib/actions/dashboard-stats.ts
'use server'

import { createSupabaseServerClient, createSupabaseServiceClient } from '@/lib/supabase/server'

/** Son 30 günün soru üretim sayıları (Tümünü kapsayacak şekilde SQL ile) */
export async function getQuestionProductionTrend() {
  const supabase = createSupabaseServiceClient()
  
  const { data, error } = await supabase.rpc('get_question_production_trend_v2')
  
  if (error) {
    console.error('Trend Error:', error)
    // Fallback: Eski usül ama limitli
    const sevenDaysAgo = new Date()
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 30)
    const { data: fallbackData } = await supabase
      .from('questions')
      .select('created_at')
      .gte('created_at', sevenDaysAgo.toISOString())
      .limit(5000)
    
    if (!fallbackData) return []
    const counts: Record<string, number> = {}
    fallbackData.forEach(q => {
      const d = new Date(q.created_at).toLocaleDateString('tr-TR', { day: '2-digit', month: '2-digit' })
      counts[d] = (counts[d] || 0) + 1
    })
    return Object.entries(counts).map(([date, count]) => ({ date, count })).reverse()
  }

  return data.map((item: any) => ({
    date: new Date(item.day).toLocaleDateString('tr-TR', { day: '2-digit', month: '2-digit' }),
    count: item.count
  }))
}

/** Konu (Topic) bazlı soru dağılımı - Tüm soruları kapsar */
export async function getTopicDistribution() {
  const supabase = createSupabaseServiceClient()
  
  // SQL Join ve Group By ile tüm veriyi çek
  const { data, error } = await supabase.from('questions_by_topic').select('*')
  
  if (error) {
    console.error('Topic Dist Error:', error)
    return []
  }

  return data.map(item => ({
    name: item.topic_title || 'Bilinmiyor',
    value: item.question_count
  }))
}

/** Kalite skor dağılımı - Tüm soruları kapsar */
export async function getScoreDistribution() {
  const supabase = createSupabaseServiceClient()
  
  // 0.5'lik aralıklarla histogram
  const { data, error } = await supabase.rpc('get_score_distribution')
  
  if (error) {
    console.error('Score Dist Error:', error)
    return []
  }

  return data.map((item: any) => ({
    range: item.range_label,
    count: item.count
  }))
}

/** Zorluk (Sınav Uygunluğu) Dağılımı - Tüm soruları kapsar */
export async function getDifficultyDistribution() {
  const supabase = createSupabaseServiceClient()
  
  const { data, error } = await supabase.rpc('get_difficulty_distribution')
  
  if (error) {
    console.error('Difficulty Dist Error:', error)
    return []
  }

  return [
    { range: 'Ortaöğretim', count: data.find((d: any) => d.label === 'ortaogretim')?.count || 0 },
    { range: 'Önlisans', count: data.find((d: any) => d.label === 'onlisans')?.count || 0 },
    { range: 'Lisans', count: data.find((d: any) => d.label === 'lisans')?.count || 0 }
  ]
}

/** Genel özet istatistikler - Bypasses RLS to ensure accurate admin overview */
export async function getGeneralStats() {
  // Stats should reflect the full state of the DB, so we use the service role client here
  const supabaseAdmin = createSupabaseServiceClient()
  
  const [
    { count: totalQuestions },
    { count: draftCount },
    { count: publishedCount },
    { count: rejectedCount },
    { count: userCount }
  ] = await Promise.all([
    supabaseAdmin.from('questions').select('*', { count: 'exact', head: true }),
    supabaseAdmin.from('questions').select('*', { count: 'exact', head: true }).in('status', ['draft', 'draft_flagged', 'pending_ai_review']),
    supabaseAdmin.from('questions').select('*', { count: 'exact', head: true }).eq('status', 'published'),
    supabaseAdmin.from('questions').select('*', { count: 'exact', head: true }).eq('status', 'ai_rejected'),
    supabaseAdmin.from('user_profiles').select('*', { count: 'exact', head: true })
  ])

  return {
    totalQuestions:  totalQuestions  ?? 0,
    draftCount:      draftCount      ?? 0,
    publishedCount:  publishedCount  ?? 0,
    rejectedCount:   rejectedCount   ?? 0,
    userCount:       userCount       ?? 0
  }
}

