import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { getInventoryNeeds } from '@/lib/pipeline/inventory-check'
import { generateQuestionsForLesson } from '@/lib/pipeline/stage1-generate'
import { runAutoFilter } from '@/lib/pipeline/stage2-auto-filter'
import { runAIReview } from '@/lib/pipeline/stage3-ai-review'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
const CRON_SECRET = process.env.CRON_SECRET

export async function GET(request: NextRequest) {
  // Cron güvenlik doğrulaması
  const authHeader = request.headers.get('authorization')
  if (authHeader !== `Bearer ${CRON_SECRET}`) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const supabase = createClient(supabaseUrl, supabaseServiceKey)

  // Job kaydı oluştur
  const { data: job, error: jobError } = await supabase
    .from('generation_jobs')
    .insert({ trigger_type: 'scheduler', status: 'running' })
    .select()
    .single()

  if (jobError || !job) {
    return NextResponse.json({ error: 'Job oluşturulamadı', details: jobError }, { status: 500 })
  }

  try {
    // 1. Inventory analizi
    const needs = await getInventoryNeeds()

    if (needs.length === 0) {
      await supabase
        .from('generation_jobs')
        .update({ status: 'completed', completed_at: new Date().toISOString() })
        .eq('id', job.id)
      return NextResponse.json({ message: 'Tüm dersler yeterli içeriğe sahip' })
    }

    let totalGenerated = 0, totalDuplicate = 0,
        totalAutoRejected = 0, totalAIRejected = 0, totalDraftCount = 0

    // 2. Her ders için üretim (en fazla 5 ders / gece, rate limiting)
    const processNeeds = needs.slice(0, 5)

    for (const need of processNeeds) {
      // Önce bekleyen regeneration request'leri işle
      const { data: regenRequests } = await supabase
        .from('regeneration_requests')
        .select(`
            *,
            rejection_reasons ( label_tr )
        `)
        .eq('lesson_id', need.lesson_id)
        .eq('status', 'pending')
        .lt('attempt_count', 3)   // Max 3 deneme
        .limit(3)

      if (regenRequests && regenRequests.length > 0) {
        for (const regen of regenRequests) {
          await supabase
            .from('regeneration_requests')
            .update({ status: 'processing', attempt_count: regen.attempt_count + 1 })
            .eq('id', regen.id)

          const regenResult = await generateQuestionsForLesson({
            jobId: job.id,
            lessonId: need.lesson_id,
            topicSlug: need.lesson_title.toLowerCase().replace(/\s+/g, '-'),
            topicTitle: need.topic_title,
            lessonTitle: need.lesson_title,
            count: 3,  // Yeniden üretimde 3 soru
            rejectionContext: {
              reason: (regen as any).rejection_reasons?.label_tr ?? regen.rejection_reason_code,
              note: regen.admin_note ?? undefined,
            },
          })

          totalGenerated += regenResult.generated
          totalDuplicate += regenResult.duplicatesSkipped
        }
      }

      // Normal üretim
      const result = await generateQuestionsForLesson({
        jobId: job.id,
        lessonId: need.lesson_id,
        topicSlug: need.lesson_title.toLowerCase().replace(/\s+/g, '-'),
        topicTitle: need.topic_title,
        lessonTitle: need.lesson_title,
        count: need.needed_count,
        errorRate: need.avg_correct_rate !== null ? 1 - need.avg_correct_rate : null,
      })

      totalGenerated += result.generated
      totalDuplicate += result.duplicatesSkipped

      // Dersler arası kısa bekleme
      await new Promise(r => setTimeout(r, 1000))
    }

    // 3. Stage 2: Otomatik filtre
    const filterResult = await runAutoFilter(job.id)
    totalAutoRejected = filterResult.rejected

    // 4. Stage 3: AI self-review
    const reviewResult = await runAIReview(job.id)
    totalAIRejected = reviewResult.aiRejected
    totalDraftCount = reviewResult.draft + reviewResult.draftFlagged

    // 5. Regeneration request'leri tamamla
    await supabase
      .from('regeneration_requests')
      .update({ status: 'completed', processed_at: new Date().toISOString() })
      .eq('status', 'processing')

    // 6. Job'ı güncelle
    await supabase
      .from('generation_jobs')
      .update({
        status: 'completed',
        generated_count: totalGenerated,
        duplicate_skipped: totalDuplicate,
        auto_rejected_count: totalAutoRejected,
        ai_rejected_count: totalAIRejected,
        draft_count: totalDraftCount,
        completed_at: new Date().toISOString(),
      })
      .eq('id', job.id)

    return NextResponse.json({
      job_id: job.id,
      generated: totalGenerated,
      duplicate_skipped: totalDuplicate,
      auto_rejected: totalAutoRejected,
      ai_rejected: totalAIRejected,
      added_to_queue: totalDraftCount,
    })

  } catch (error) {
    console.error('Cron job error:', error)
    await supabase
      .from('generation_jobs')
      .update({
        status: 'failed',
        error_message: String(error),
        completed_at: new Date().toISOString(),
      })
      .eq('id', job.id)

    return NextResponse.json({ error: String(error) }, { status: 500 })
  }
}
