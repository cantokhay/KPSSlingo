// components/providers/toast-provider.tsx
'use client'

import { Toaster } from 'sonner'
import { useTheme } from 'next-themes'

export function ToastProvider() {
  const { theme } = useTheme()

  return (
    <Toaster
      position="bottom-right"
      theme={theme as 'light' | 'dark' | 'system'}
      richColors
      closeButton
      toastOptions={{
        style: {
          fontFamily: 'var(--font-plus-jakarta-sans)',
          fontSize: '0.8125rem',
          fontWeight: '600',
          borderRadius: '12px',
        },
        duration: 4000,
      }}
    />
  )
}
