// components/scroll-to-top.tsx
'use client'

import { useEffect, useState } from 'react'

export function ScrollToTop() {
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    const onScroll = () => setVisible(window.scrollY > 400)
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  function scrollTop() {
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  return (
    <button
      onClick={scrollTop}
      aria-label="Sayfanın en üstüne git"
      className={`
        fixed bottom-8 right-8 z-50
        w-12 h-12 rounded-2xl
        bg-brand-primary text-white
        shadow-xl shadow-brand-primary/30
        flex items-center justify-center text-xl font-bold
        transition-all duration-300
        hover:bg-brand-light hover:scale-110 hover:-translate-y-0.5
        active:scale-95
        ${visible
          ? 'opacity-100 translate-y-0 pointer-events-auto'
          : 'opacity-0 translate-y-4 pointer-events-none'
        }
      `}
    >
      ↑
    </button>
  )
}
