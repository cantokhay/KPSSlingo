// lib/actions/question-actions.ts
'use server'

import { revalidatePath } from 'next/cache'
import { createSupabaseServerClient, createSupabaseServiceClient } from '@/lib/supabase/server'
import { calculateQuestionScore } from '@/lib/utils/score-calculator'

// ── Admin auth helper ─────────────────────────────────────────────────────────
// ── Admin/Superadmin auth helper ─────────────────────────────────────────────────────────
async function requireAdmin() {
  const supabase = await createSupabaseServerClient()
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) throw new Error('Oturum bulunamadı')

  // Rolü doğrudan JWT'den (app_metadata) kontrol et
  const role = user.app_metadata?.role
  
  if (role !== 'admin' && role !== 'superadmin') {
    throw new Error('Bu işlem için yetkiniz yok')
  }
  
  return user
}

// ── Approve Question ──────────────────────────────────────────────────────────
export async function approveQuestion(questionId: string) {
  const admin = await requireAdmin()
  const supabase = createSupabaseServiceClient()

  // Önce soruyu çek (skor hesaplama için)
  const { data: q } = await supabase
    .from('questions')
    .select('body, explanation, status, source')
    .eq('id', questionId)
    .single()

  const score = q ? calculateQuestionScore({
    body:        q.body,
    explanation: q.explanation,
    status:      q.status,
    source:      q.source,
  }) : null

  const { error } = await supabase
    .from('questions')
    .update({
      status:          'published',
      reviewed_by:     admin.id,
      reviewed_at:     new Date().toISOString(),
      ...(score !== null && { ai_review_score: score }),
    })
    .eq('id', questionId)
    .in('status', ['draft', 'draft_flagged', 'ai_rejected'])

  if (error) throw new Error('Onaylama başarısız: ' + error.message)

  revalidatePath('/dashboard/questions')
  revalidatePath(`/dashboard/questions/${questionId}`)
  revalidatePath('/dashboard')

  return { success: true, message: '✓ Soru yayınlandı' }
}

// ── Reject Question ───────────────────────────────────────────────────────────
export async function rejectQuestion(questionId: string) {
  await requireAdmin()
  const supabase = createSupabaseServiceClient()

  const { error } = await supabase
    .from('questions')
    .update({ status: 'archived' })
    .eq('id', questionId)

  if (error) throw new Error('Reddetme başarısız: ' + error.message)

  revalidatePath('/dashboard/questions')
  revalidatePath(`/dashboard/questions/${questionId}`)
  revalidatePath('/dashboard')

  return { success: true, message: 'Soru arşivlendi' }
}

// ── Update Question ───────────────────────────────────────────────────────────
export async function updateQuestion(
  questionId: string,
  payload: {
    body?: string
    explanation?: string
    correct_option?: string
    options?: { label: string; body: string }[]
  }
) {
  const admin = await requireAdmin()
  const supabase = createSupabaseServiceClient()

  const { error: qError } = await supabase
    .from('questions')
    .update({
      ...(payload.body && { body: payload.body }),
      ...(payload.explanation !== undefined && { explanation: payload.explanation }),
    })
    .eq('id', questionId)

  if (qError) throw new Error('Soru güncellenemedi: ' + qError.message)

  // Doğru şıkkı güvenli tabloya kaydet
  if (payload.correct_option) {
    const { error: aError } = await supabase
      .from('question_answers')
      .upsert({
        question_id: questionId,
        correct_option: payload.correct_option,
      })

    if (aError) throw new Error('Doğru şık güncellenemedi: ' + aError.message)
  }

  if (payload.options) {
    for (const opt of payload.options) {
      await supabase
        .from('question_options')
        .update({ body: opt.body })
        .eq('question_id', questionId)
        .eq('label', opt.label)
    }
  }

  revalidatePath('/dashboard/questions')
  revalidatePath(`/dashboard/questions/${questionId}`)

  return { success: true, message: '✓ Soru güncellendi' }
}

// ── Bulk Approve ──────────────────────────────────────────────────────────────
export async function bulkApproveQuestions(questionIds: string[]) {
  const admin = await requireAdmin()
  const supabase = createSupabaseServiceClient()

  const { error } = await supabase
    .from('questions')
    .update({
      status:      'published',
      reviewed_by: admin.id,
      reviewed_at: new Date().toISOString(),
    })
    .in('id', questionIds)
    .in('status', ['draft', 'draft_flagged', 'ai_rejected'])

  if (error) throw new Error('Toplu onaylama başarısız: ' + error.message)

  revalidatePath('/dashboard/questions')
  revalidatePath('/dashboard')

  return { success: true, message: `✓ ${questionIds.length} soru yayınlandı` }
}

// ── Reject With Reason (No Regeneration) ────────────────────────────────────────
export async function rejectQuestionWithReason(
  questionId: string,
  lessonId: string,
  rejectionReasonCode: string,
  adminNote?: string
) {
  const admin = await requireAdmin()
  const supabase = createSupabaseServiceClient()

  const { error: rejectError } = await supabase
    .from('questions')
    .update({
      status:           'ai_rejected',
      rejection_reason: rejectionReasonCode,
      rejected_stage:   'admin',
      reviewed_by:      admin.id,
      reviewed_at:      new Date().toISOString(),
    })
    .eq('id', questionId)

  if (rejectError) throw new Error('Reddetme başarısız: ' + rejectError.message)

  revalidatePath('/dashboard/questions')
  revalidatePath(`/dashboard/questions/${questionId}`)
  revalidatePath('/dashboard')

  return { success: true, message: 'Soru reddedildi. Manuel düzeltme için reddedilenler listesinde tutuluyor.' }
}
