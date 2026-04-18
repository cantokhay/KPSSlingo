'use server'

import { createSupabaseServiceClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export async function approveAdmin(userId: string) {
  const supabaseAdmin = createSupabaseServiceClient()

  // user_roles tablosunda role = admin olarak güncelliyoruz veya ekliyoruz.
  const { error } = await supabaseAdmin.from('user_roles').upsert(
    { user_id: userId, role: 'admin' },
    { onConflict: 'user_id' }
  )

  if (error) {
    return error.message
  }

  revalidatePath('/dashboard/users')
  return null
}

export async function demoteUser(userId: string) {
  const supabaseAdmin = createSupabaseServiceClient()

  // user_roles tablosundan siliyoruz, böylece varsayılan olarak role 'student' (veya None) olur.
  const { error } = await supabaseAdmin.from('user_roles').delete().eq('user_id', userId)

  if (error) {
    return error.message
  }

  revalidatePath('/dashboard/users')
  return null
}

export async function deleteUser(userId: string) {
  const supabaseAdmin = createSupabaseServiceClient()

  // Auth'dan kullanıcıyı kalıcı olarak siliyoruz. Postgres kaskad ile public tabloları silmeli.
  const { error } = await supabaseAdmin.auth.admin.deleteUser(userId)

  if (error) {
    return error.message
  }

  revalidatePath('/dashboard/users')
  return null
}
