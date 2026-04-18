import { createSupabaseServiceClient, createSupabaseServerClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { UserActions } from './user-actions'

export default async function UsersPage() {
  const supabase = await createSupabaseServerClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const { data: roleData } = await supabase
    .from('user_roles')
    .select('role')
    .eq('user_id', user.id)
    .single()

  const currentRole = roleData?.role || 'student'

  if (currentRole !== 'superadmin' && currentRole !== 'admin') {
    redirect('/dashboard')
  }

  const supabaseAdmin = createSupabaseServiceClient()
  
  const { data: usersData, error } = await supabaseAdmin.auth.admin.listUsers()
  
  if (error) {
    return <div className="p-4 bg-semantic-error/10 text-semantic-error rounded-card">Error loading users: {error.message}</div>
  }

  const { data: userRoles } = await supabaseAdmin.from('user_roles').select('*')

  const users = usersData.users
    .filter(u => u.email !== 'multimicro14@gmail.com')
    .map(u => {
      const roleRecord = userRoles?.find(r => r.user_id === u.id)
      return {
        ...u,
        dbRole: roleRecord?.role ?? 'student'
      }
    });

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-extrabold text-brand-primary tracking-tighter">
          Kullanıcı Yönetimi
        </h1>
      </div>
      
      <div className="bg-surface border border-ink-disabled/10 rounded-[24px] shadow-sm overflow-hidden text-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="bg-surface-alt border-b border-ink-disabled/10 text-xs uppercase tracking-widest text-ink-secondary">
              <tr>
                <th className="px-6 py-4 font-bold">Kullanıcı Bilgileri</th>
                <th className="px-6 py-4 font-bold">Kayıt İsteği</th>
                <th className="px-6 py-4 font-bold">DB Rolü</th>
                <th className="px-6 py-4 font-bold text-right">İşlemler</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-ink-disabled/5 font-medium text-ink-primary">
              {users.map(u => (
                <tr key={u.id} className="hover:bg-surface-muted transition-colors">
                  <td className="px-6 py-4">
                    <div className="font-bold">{u.email}</div>
                    <div className="text-xs text-ink-secondary mt-0.5">{new Date(u.created_at).toLocaleDateString('tr-TR')}</div>
                  </td>
                  <td className="px-6 py-4">
                    {u.user_metadata?.requested_role === 'admin' ? (
                      <span className="bg-brand-primary/10 text-brand-primary px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider">
                        Admin Talep Etti
                      </span>
                    ) : (
                      <span className="bg-ink-disabled/10 text-ink-secondary px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider">
                        Normal Kayıt
                      </span>
                    )}
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${u.dbRole === 'admin' ? 'bg-semantic-success/10 text-semantic-success' : 'bg-ink-disabled/5 text-ink-secondary'}`}>
                      {u.dbRole}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <UserActions userId={u.id} dbRole={u.dbRole} currentRole={currentRole} />
                  </td>
                </tr>
              ))}
              
              {users.length === 0 && (
                <tr>
                  <td colSpan={4} className="px-6 py-12 text-center text-ink-secondary font-bold">
                    Başka kullanıcı bulunamadı.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
