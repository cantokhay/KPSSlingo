// app/login/page.tsx
'use client'

import { useState, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { createSupabaseBrowserClient } from '@/lib/supabase/client'
import Link from 'next/link'

import { ThemeToggle } from '@/components/ui/theme-toggle'

function LoginForm() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const errorParam = searchParams.get('error')
  const reason     = searchParams.get('reason')

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(
    reason === 'idle'
      ? '⏰ 15 dakika boyunca işlem yapılmadı. Güvenliğiniz için oturumunuz sonlandırıldı.'
      : errorParam === 'unauthorized'
      ? 'Bu hesabın admin yetkisi yok.'
      : null
  )
  const [loading, setLoading] = useState(false)

  async function handleLogin(e?: React.FormEvent) {
    if (e) e.preventDefault()
    if (!email || !password) return

    setLoading(true)
    setError(null)

    const supabase = createSupabaseBrowserClient()
    const { data, error: authError } = await supabase.auth.signInWithPassword({ email, password })

    if (authError) {
      setError(authError.message)
      setLoading(false)
      return
    }

    // Role check
    const role = data.user?.user_metadata?.role
    if (role !== 'admin') {
      await supabase.auth.signOut()
      setError('Bu hesabın admin yetkisi yok.')
      setLoading(false)
      return
    }

    router.refresh()
    router.push('/dashboard')
  }

  return (
    <div className="min-h-screen bg-surface-alt flex flex-col items-center justify-center p-6 bg-[radial-gradient(circle_at_top_right,_var(--color-brand-light)_0%,_transparent_25%),_radial-gradient(circle_at_bottom_left,_var(--color-brand-primary)_0%,_transparent_25%)]">
      <div className="absolute top-8 right-8">
        <ThemeToggle />
      </div>
      
      <div className="w-full max-w-md animate-in fade-in zoom-in-95 duration-500">
        <div className="bg-surface border border-ink-disabled/10 rounded-[32px] p-10 shadow-2xl overflow-hidden relative">
          {/* Logo Section */}
          <div className="text-center mb-10">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-brand-primary rounded-2xl mb-4 shadow-lg shadow-brand-primary/20 rotate-3">
              <span className="text-3xl">🎯</span>
            </div>
            <h1 className="text-3xl font-extrabold text-brand-primary tracking-tighter">
              KPSSlingo
            </h1>
            <p className="text-sm text-ink-secondary font-semibold mt-2 uppercase tracking-widest opacity-60">
              Admin Paneli
            </p>
          </div>

          <form onSubmit={handleLogin} className="space-y-6">
            <div>
              <label className="block text-xs font-bold text-ink-secondary uppercase tracking-widest mb-2 ml-1">
                E-posta Adresi
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoComplete="email"
                className="w-full bg-surface-alt border border-ink-disabled/10 rounded-card px-5 py-4
                           text-sm text-ink-primary focus:outline-none focus:border-brand-primary
                           focus:ring-4 focus:ring-brand-primary/10 transition-all font-medium"
                placeholder="admin@kpsslingo.com"
                required
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-ink-secondary uppercase tracking-widest mb-2 ml-1">
                Şifre
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="current-password"
                className="w-full bg-surface-alt border border-ink-disabled/10 rounded-card px-5 py-4
                           text-sm text-ink-primary focus:outline-none focus:border-brand-primary
                           focus:ring-4 focus:ring-brand-primary/10 transition-all font-medium"
                placeholder="••••••••"
                required
              />
            </div>

            {error && (
              <div className="bg-semantic-error/10 border border-semantic-error/20 text-semantic-error text-xs font-bold p-4 rounded-card animate-in shake-in-1 duration-300">
                ⚠️ {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-brand-primary text-white font-bold py-4 rounded-card
                         shadow-xl shadow-brand-primary/30 hover:bg-brand-light hover:-translate-y-0.5
                         transition-all active:translate-y-0 active:shadow-lg disabled:opacity-50
                         disabled:translate-y-0 disabled:shadow-none flex items-center justify-center gap-2"
            >
              {loading ? (
                <>
                  <span className="animate-spin text-lg">⏳</span>
                  <span>Giriş Yapılıyor...</span>
                </>
              ) : (
                'Giriş Yap →'
              )}
            </button>
          </form>

          {/* Footer Decoration */}
          <div className="mt-10 pt-6 border-t border-ink-disabled/5 text-center space-y-4">
            <Link href="/register" className="text-xs font-bold text-brand-primary hover:underline uppercase tracking-widest">
              Yeni Admin Hesabı Oluştur
            </Link>
            <p className="text-[10px] text-ink-disabled font-bold uppercase tracking-widest">
              Giriş yaparak kullanım koşullarını kabul etmiş olursunuz.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default function LoginPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-surface-alt flex items-center justify-center">
        <div className="animate-spin text-4xl text-brand-primary">⏳</div>
      </div>
    }>
      <LoginForm />
    </Suspense>
  )
}
