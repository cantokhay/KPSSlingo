'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createSupabaseBrowserClient } from '@/lib/supabase/client'

/**
 * AdminSessionGuard — Client-Side İkinci Güvenlik Katmanı
 *
 * Supabase oturumu açık olsa bile, sessionStorage'daki 'admin_verified' flag'ini
 * kontrol eder. Tab veya tarayıcı kapanınca sessionStorage sifirlanır; dolayısıyla
 * her yeni açılışta kullanıcı tekrar login yapmak zorundadır.
 */
export function AdminSessionGuard() {
  const router = useRouter()

  useEffect(() => {
    const verified = window.sessionStorage.getItem('admin_verified')

    if (!verified) {
      // Flag yoksa: Supabase oturumunu da sonlandır, login'e yönlendir
      const supabase = createSupabaseBrowserClient()
      supabase.auth.signOut().finally(() => {
        router.replace('/login?reason=session_expired')
      })
    }
  }, [router])

  return null
}
