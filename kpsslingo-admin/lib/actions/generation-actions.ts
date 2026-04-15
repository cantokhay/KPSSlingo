// lib/actions/generation-actions.ts
'use server'

import { revalidatePath } from 'next/cache'
import { createSupabaseServerClient, createSupabaseServiceClient } from '@/lib/supabase/server'
import { GoogleGenerativeAI } from "@google/generative-ai"
import { generateQuestionsForLesson as pipelineGenerate } from '@/lib/pipeline/stage1-generate'
import { runAutoFilter } from '@/lib/pipeline/stage2-auto-filter'
import { runAIReview } from '@/lib/pipeline/stage3-ai-review'
import { getInventoryNeeds } from '@/lib/pipeline/inventory-check'

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!)

async function requireAdmin() {
  const supabase = await createSupabaseServerClient()
  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user || user.user_metadata?.role !== 'admin') {
    throw new Error('Unauthorized')
  }
  return user
}

export async function generateQuestionsForLesson(
  lessonId: string,
  lessonTitle: string,
  topicTitle: string,
  count: number = 10
): Promise<{ generated: number; errors: number }> {
  await requireAdmin()

  const supabase = createSupabaseServiceClient()

  // 1. Create a job for this manual trigger
  const { data: job, error: jobError } = await supabase
    .from('generation_jobs')
    .insert({ trigger_type: 'manual', status: 'running' })
    .select()
    .single()

  if (jobError || !job) {
    throw new Error('Bir üretim işi (job) başlatılamadı.')
  }

  try {
    // 2. Stage 1: Generation
    const result = await pipelineGenerate({
      jobId: job.id,
      lessonId,
      topicSlug: lessonTitle.toLowerCase().replace(/\s+/g, '-'),
      topicTitle,
      lessonTitle,
      count
    })

    if (result.errors > 0 && result.generated === 0) {
      throw new Error('Soru üretimi sırasında AI hatası oluştu.')
    }

    // 3. Stage 2: Auto Filter
    await runAutoFilter(job.id)

    // 4. Stage 3: AI Review
    const reviewResult = await runAIReview(job.id)

    // 5. Update Job
    await supabase
      .from('generation_jobs')
      .update({
        status: 'completed',
        generated_count: result.generated,
        duplicate_skipped: result.duplicatesSkipped,
        draft_count: reviewResult.draft + reviewResult.draftFlagged,
        completed_at: new Date().toISOString()
      })
      .eq('id', job.id)

    revalidatePath('/dashboard/questions')
    revalidatePath('/dashboard')
    
    return { 
      generated: reviewResult.draft + reviewResult.draftFlagged, 
      errors: result.errors 
    }
  } catch (err: any) {
    console.error("Generation error:", err)
    await supabase
      .from('generation_jobs')
      .update({ status: 'failed', error_message: err.message })
      .eq('id', job.id)
    throw new Error("Soru üretimi sırasında bir hata oluştu: " + err.message)
  }
}

/**
 * Executes the entire daily pipeline for all lessons needing attention.
 */
export async function runDailyPipelineAction(config?: {
  minThreshold?: number,
  targetCount?: number
}) {
  await requireAdmin()
  const supabase = createSupabaseServiceClient()

  const { data: job, error: jobError } = await supabase
    .from('generation_jobs')
    .insert({ trigger_type: 'manual', status: 'running' })
    .select()
    .single()

  if (jobError || !job) throw new Error('Job starting error')

  try {
    const needs = await getInventoryNeeds(config)
    if (needs.length === 0) {
      await supabase.from('generation_jobs').update({ status: 'completed' }).eq('id', job.id)
      return { message: 'Tüm dersler yeterli içeriğe sahip.' }
    }

    // Process top 5 needs
    const processNeeds = needs.slice(0, 5)
    let totalGenerated = 0

    for (const need of processNeeds) {
      const res = await pipelineGenerate({
        jobId: job.id,
        lessonId: need.lesson_id,
        topicSlug: need.lesson_title.toLowerCase().replace(/\s+/g, '-'),
        topicTitle: need.topic_title,
        lessonTitle: need.lesson_title,
        count: need.needed_count,
        errorRate: need.avg_correct_rate !== null ? 1 - need.avg_correct_rate : null,
      })
      totalGenerated += res.generated
    }

    await runAutoFilter(job.id)
    const review = await runAIReview(job.id)
    const finalCount = review.draft + review.draftFlagged

    await supabase.from('generation_jobs').update({
      status: 'completed',
      generated_count: totalGenerated,
      draft_count: finalCount,
      completed_at: new Date().toISOString()
    }).eq('id', job.id)

    revalidatePath('/dashboard')
    return { lessonsProcessed: processNeeds.length, questionsAdded: finalCount }
  } catch (err: any) {
    await supabase.from('generation_jobs').update({ status: 'failed', error_message: err.message }).eq('id', job.id)
    throw err
  }
}
