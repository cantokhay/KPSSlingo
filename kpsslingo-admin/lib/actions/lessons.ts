// lib/actions/lessons.ts
'use server'

import { revalidatePath } from 'next/cache'
import { createSupabaseServerClient, createSupabaseServiceClient } from '@/lib/supabase/server'

// ── Admin auth helper ─────────────────────────────────────────────────────────
async function requireAdmin() {
  const supabase = await createSupabaseServerClient()
  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user || user.user_metadata?.role !== 'admin') {
    throw new Error('Unauthorized')
  }
  return user
}

export type LessonPayload = {
  title: string
  topic_id: string
  difficulty: 'beginner' | 'intermediate' | 'advanced'
  order: number
  description?: string
  xp_reward?: number
  status?: 'draft' | 'published' | 'archived'
}

// ── Create Lesson ─────────────────────────────────────────────────────────────
export async function createLesson(payload: LessonPayload) {
  await requireAdmin()
  const supabase = createSupabaseServiceClient()

  const { error } = await supabase.from('lessons').insert({
    title:       payload.title,
    topic_id:    payload.topic_id,
    difficulty:  payload.difficulty,
    order:       payload.order,
    description: payload.description ?? null,
    xp_reward:   payload.xp_reward ?? 10,
    status:      payload.status ?? 'draft',
  })

  if (error) throw new Error('Ders oluşturulamadı: ' + error.message)

  revalidatePath('/dashboard/lessons')
  revalidatePath('/dashboard')

  return { success: true, message: '✓ Ders başarıyla oluşturuldu' }
}

// ── Update Lesson ─────────────────────────────────────────────────────────────
export async function updateLesson(lessonId: string, payload: Partial<LessonPayload>) {
  await requireAdmin()
  const supabase = createSupabaseServiceClient()

  const { error } = await supabase
    .from('lessons')
    .update({
      ...(payload.title       !== undefined && { title:       payload.title }),
      ...(payload.topic_id    !== undefined && { topic_id:    payload.topic_id }),
      ...(payload.difficulty  !== undefined && { difficulty:  payload.difficulty }),
      ...(payload.order       !== undefined && { order:       payload.order }),
      ...(payload.description !== undefined && { description: payload.description }),
      ...(payload.xp_reward   !== undefined && { xp_reward:   payload.xp_reward }),
      ...(payload.status      !== undefined && { status:       payload.status }),
      updated_at: new Date().toISOString(),
    })
    .eq('id', lessonId)

  if (error) throw new Error('Ders güncellenemedi: ' + error.message)

  revalidatePath('/dashboard/lessons')
  revalidatePath('/dashboard')

  return { success: true, message: '✓ Ders başarıyla güncellendi' }
}

// ── Soft Delete (Pasife Al) ───────────────────────────────────────────────────
export async function softDeleteLesson(lessonId: string) {
  await requireAdmin()
  const supabase = createSupabaseServiceClient()

  // status = 'archived' + deleted_at timestamp (soft delete)
  const { error } = await supabase
    .from('lessons')
    .update({
      status:     'archived',
      deleted_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', lessonId)

  if (error) throw new Error('Ders pasife alınamadı: ' + error.message)

  revalidatePath('/dashboard/lessons')
  revalidatePath('/dashboard')

  return { success: true, message: 'Ders arşivlendi' }
}

// ── Restore Lesson ────────────────────────────────────────────────────────────
export async function restoreLesson(lessonId: string) {
  await requireAdmin()
  const supabase = createSupabaseServiceClient()

  const { error } = await supabase
    .from('lessons')
    .update({
      status:     'draft',
      deleted_at: null,
      updated_at: new Date().toISOString(),
    })
    .eq('id', lessonId)

  if (error) throw new Error('Ders geri yüklenemedi: ' + error.message)

  revalidatePath('/dashboard/lessons')

  return { success: true, message: '✓ Ders yeniden aktifleştirildi' }
}
