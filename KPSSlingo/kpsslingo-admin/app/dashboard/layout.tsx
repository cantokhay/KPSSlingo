// app/dashboard/layout.tsx
import { redirect } from 'next/navigation'
import { createSupabaseServerClient, createSupabaseServiceClient } from '@/lib/supabase/server'
import { Sidebar } from '@/components/sidebar'
import { IdleTimerWrapper } from '@/components/idle-timer-wrapper'
import { ScrollToTop } from '@/components/scroll-to-top'
import { ToastProvider } from '@/components/providers/toast-provider'
import { PageTransition } from '@/components/page-transition'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = await createSupabaseServerClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/login')
  }

  const { data: roleData } = await supabase
    .from('user_roles')
    .select('role')
    .eq('user_id', user.id)
    .single()

  const dbRole = roleData?.role;
  if (dbRole !== 'admin' && dbRole !== 'superadmin') {
    redirect('/login')
  }

  const isSuperAdmin = dbRole === 'superadmin';

  // Sidebar'daki "Bekleyen" sayısını dashboard ile tutarlı yapıyoruz
  const supabaseAdmin = createSupabaseServiceClient()
  const { count: draftCount } = await supabaseAdmin
    .from('questions')
    .select('*', { count: 'exact', head: true })
    .in('status', ['draft', 'draft_flagged', 'pending_ai_review'])

  return (
    <IdleTimerWrapper>
      <div className="flex min-h-screen bg-surface-alt font-sans">
        <Sidebar draftCount={draftCount ?? 0} isSuperAdmin={isSuperAdmin} />
        
        <main className="flex-1 overflow-x-hidden">
          <div className="max-w-6xl mx-auto px-6 py-10 md:px-12">
            <PageTransition>
              {children}
            </PageTransition>
          </div>
        </main>
      </div>

      <ScrollToTop />
      <ToastProvider />
    </IdleTimerWrapper>
  )
}
