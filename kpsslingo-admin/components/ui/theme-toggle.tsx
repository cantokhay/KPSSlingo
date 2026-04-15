// components/ui/theme-toggle.tsx
'use client'

import { useTheme } from 'next-themes'
import { useEffect, useState } from 'react'

export function ThemeToggle() {
  const { setTheme, resolvedTheme } = useTheme()
  const [mounted, setMounted] = useState(false)

  useEffect(() => setMounted(true), [])
  if (!mounted) return <div className="w-10 h-10" />

  const isDark = resolvedTheme === 'dark'

  return (
    <button
      onClick={() => setTheme(isDark ? 'light' : 'dark')}
      title={isDark ? 'Açık temaya geç' : 'Koyu temaya geç'}
      className="
        w-full flex items-center gap-3 px-4 py-3 rounded-card text-sm font-bold
        transition-all duration-300 group
        text-ink-secondary dark:text-gray-400
        hover:bg-surface-muted dark:hover:bg-gray-800 hover:text-ink-primary dark:hover:text-gray-100
      "
    >
      <div className="w-6 h-6 flex items-center justify-center relative overflow-hidden">
        <span className={`
          absolute transition-all duration-500 transform
          ${isDark ? 'translate-y-0 opacity-100 rotate-0' : 'translate-y-10 opacity-0 rotate-90'}
        `}>
          ☀️
        </span>
        <span className={`
          absolute transition-all duration-500 transform
          ${!isDark ? 'translate-y-0 opacity-100 rotate-0' : 'translate-y-10 opacity-0 -rotate-90'}
        `}>
          🌙
        </span>
      </div>
      <span className="flex-1 text-left">{isDark ? 'Açık Tema' : 'Koyu Tema'}</span>
    </button>
  )
}
