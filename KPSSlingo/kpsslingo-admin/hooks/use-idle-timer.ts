// hooks/use-idle-timer.ts
'use client'

import { useEffect, useRef, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import { createSupabaseBrowserClient } from '@/lib/supabase/client'

const IDLE_TIMEOUT_MS = 15 * 60 * 1000 // 15 dakika

const ACTIVITY_EVENTS = [
  'mousemove',
  'mousedown',
  'keydown',
  'touchstart',
  'scroll',
  'click',
] as const

export function useIdleTimer() {
  const router = useRouter()
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  const signOutAndRedirect = useCallback(async () => {
    const supabase = createSupabaseBrowserClient()
    await supabase.auth.signOut()
    router.push('/login?reason=idle')
  }, [router])

  const resetTimer = useCallback(() => {
    if (timerRef.current) {
      clearTimeout(timerRef.current)
    }
    timerRef.current = setTimeout(signOutAndRedirect, IDLE_TIMEOUT_MS)
  }, [signOutAndRedirect])

  useEffect(() => {
    // Başlangıçta timer'ı başlat
    resetTimer()

    // Tüm kullanıcı aktivite eventlerini dinle
    ACTIVITY_EVENTS.forEach((event) => {
      window.addEventListener(event, resetTimer, { passive: true })
    })

    return () => {
      // Cleanup: eventleri kaldır ve timer'ı temizle
      ACTIVITY_EVENTS.forEach((event) => {
        window.removeEventListener(event, resetTimer)
      })
      if (timerRef.current) {
        clearTimeout(timerRef.current)
      }
    }
  }, [resetTimer])
}
