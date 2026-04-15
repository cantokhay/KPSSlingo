// components/idle-timer-wrapper.tsx
'use client'

import { useIdleTimer } from '@/hooks/use-idle-timer'

/**
 * Kullanıcıyı 15 dakika hareketsizlik sonrası otomatik çıkış yaptıran
 * client-side wrapper. Dashboard layout'una eklenir.
 */
export function IdleTimerWrapper({ children }: { children: React.ReactNode }) {
  useIdleTimer()
  return <>{children}</>
}
