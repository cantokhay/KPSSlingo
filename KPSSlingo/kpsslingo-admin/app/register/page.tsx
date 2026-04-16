// app/register/page.tsx
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createSupabaseBrowserClient } from '@/lib/supabase/client'
import Link from 'next/link'

import { ThemeToggle } from '@/components/ui/theme-toggle'

export default function RegisterPage() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)

  async function handleRegister(e: React.FormEvent) {
    e.preventDefault()
    if (!email || !password) return

    setLoading(true)
    setError(null)

    const supabase = createSupabaseBrowserClient()
    
    // Register as admin for testing purposes
    const { error: authError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          role: 'admin',
          full_name: 'Test Admin'
        }
      }
    })

    if (authError) {
      setError(authError.message)
      setLoading(false)
      return
    }

    setSuccess(true)
    setLoading(false)
    
    // Auto login and redirect after a short delay
    setTimeout(() => {
      router.push('/login')
    }, 3000)
  }

  return (
    <div className="min-h-screen bg-surface-alt flex flex-col items-center justify-center p-6 bg-[radial-gradient(circle_at_top_right,_var(--color-brand-light)_0%,_transparent_25%),_radial-gradient(circle_at_bottom_left,_var(--color-brand-primary)_0%,_transparent_25%)]">
      <div className="absolute top-8 right-8">
        <ThemeToggle />
      </div>

      <div className="w-full max-w-md animate-in fade-in zoom-in-95 duration-500">
        <div className="bg-surface border border-ink-disabled/10 rounded-[32px] p-10 shadow-2xl overflow-hidden relative">
          
          <div className="text-center mb-10">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-brand-primary rounded-2xl mb-4 shadow-lg shadow-brand-primary/20 -rotate-3">
              <span className="text-3xl">🔑</span>
            </div>
            <h1 className="text-3xl font-extrabold text-brand-primary tracking-tighter">
              Admin Kaydı
            </h1>
            <p className="text-sm text-ink-secondary font-semibold mt-2 uppercase tracking-widest opacity-60">
              Yeni Admin Hesabı Oluştur
            </p>
          </div>

          {success ? (
            <div className="bg-semantic-success/10 border border-semantic-success/20 text-semantic-success p-6 rounded-card text-center animate-in zoom-in duration-300">
              <div className="text-4xl mb-4">🎉</div>
              <h2 className="text-lg font-bold mb-2">Başarılı!</h2>
              <p className="text-sm font-medium">Hesabınız oluşturuldu. Giriş sayfasına yönlendiriliyorsunuz...</p>
            </div>
          ) : (
            <form onSubmit={handleRegister} className="space-y-6">
              <div>
                <label className="block text-xs font-bold text-ink-secondary uppercase tracking-widest mb-2 ml-1">
                  E-posta Adresi
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
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
                  className="w-full bg-surface-alt border border-ink-disabled/10 rounded-card px-5 py-4
                             text-sm text-ink-primary focus:outline-none focus:border-brand-primary
                             focus:ring-4 focus:ring-brand-primary/10 transition-all font-medium"
                  placeholder="••••••••"
                  required
                />
              </div>

              {error && (
                <div className="bg-semantic-error/10 border border-semantic-error/20 text-semantic-error text-xs font-bold p-4 rounded-card">
                  ⚠️ {error}
                </div>
              )}

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-brand-primary text-white font-bold py-4 rounded-card
                           shadow-xl shadow-brand-primary/30 hover:bg-brand-light hover:-translate-y-0.5
                           transition-all disabled:opacity-50 flex items-center justify-center gap-2"
              >
                {loading ? 'Kayıt Yapılıyor...' : 'Kayıt Ol →'}
              </button>

              <div className="text-center">
                <Link href="/login" className="text-xs font-bold text-brand-primary hover:underline uppercase tracking-widest">
                  Zaten hesabın var mı? Giriş Yap
                </Link>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  )
}
