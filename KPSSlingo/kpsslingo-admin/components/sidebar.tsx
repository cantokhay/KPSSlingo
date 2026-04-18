// components/sidebar.tsx
'use client'

import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { createSupabaseBrowserClient } from '@/lib/supabase/client'
import { ThemeToggle } from '@/components/ui/theme-toggle'

const navItems = [
  { href: '/dashboard',           label: 'Dashboard',  icon: '📊' },
  { href: '/dashboard/questions', label: 'Sorular',    icon: '❓' },
  { href: '/dashboard/lessons',   label: 'Dersler',    icon: '📚' },
  { href: '/dashboard/topics',    label: 'Konular',    icon: '🗂️' },
]

export function Sidebar({ draftCount, isSuperAdmin = false }: { draftCount: number, isSuperAdmin?: boolean }) {
  const pathname = usePathname()
  const router = useRouter()

  async function handleSignOut() {
    const supabase = createSupabaseBrowserClient()
    await supabase.auth.signOut()
    router.refresh()
    router.push('/login')
  }

  return (
    <aside className="w-64 shrink-0 bg-surface border-r border-ink-disabled/10 flex flex-col h-screen sticky top-0">
      {/* Logo */}
      <div className="px-6 py-6 border-b border-ink-disabled/5">
        <Link
          href="/dashboard"
          className="flex items-center gap-2 group cursor-pointer w-fit"
          title="Dashboard'a git"
        >
          <span className="text-xl font-extrabold text-brand-primary tracking-tighter group-hover:opacity-80 transition-opacity">
            KPSSlingo
          </span>
          <span className="text-[10px] font-bold text-ink-secondary bg-surface-muted px-2 py-0.5 rounded-pill uppercase tracking-widest">
            Admin
          </span>
        </Link>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-6 space-y-1">
        {[...navItems, ...(isSuperAdmin ? [{ href: '/dashboard/users', label: 'Kullanıcılar', icon: '👥' }] : [])].map((item) => {
          const isActive = pathname === item.href || 
            (item.href !== '/dashboard' && pathname.startsWith(item.href))

          return (
            <Link
              key={item.href}
              href={item.href}
              className={`
                flex items-center gap-3 px-4 py-3 rounded-card text-sm font-semibold
                transition-all duration-200
                ${isActive
                  ? 'bg-brand-primary text-white shadow-sm shadow-brand-primary/20'
                  : 'text-ink-secondary hover:bg-surface-muted hover:text-ink-primary'
                }
              `}
            >
              <span className="text-lg">{item.icon}</span>
              <span>{item.label}</span>
              
              {/* Draft Badge */}
              {item.href === '/dashboard/questions' && draftCount > 0 && (
                <span className={`
                  ml-auto text-[10px] font-bold px-1.5 py-0.5 rounded-full
                  ${isActive ? 'bg-white/20 text-white' : 'bg-semantic-warning text-white'}
                `}>
                  {draftCount}
                </span>
              )}
            </Link>
          )
        })}
      </nav>

      {/* Alt: Dark Mode Toggle + Çıkış */}
      <div className="px-3 py-4 border-t border-ink-disabled/10 space-y-1">
        <ThemeToggle />
        <button
          onClick={handleSignOut}
          className="w-full flex items-center gap-3 px-4 py-3 rounded-card text-sm font-bold text-ink-secondary hover:bg-semantic-error/5 hover:text-semantic-error transition-all duration-200"
        >
          <span className="text-lg">🚪</span>
          <span>Çıkış Yap</span>
        </button>
      </div>
    </aside>
  )
}
