'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { approveAdmin, demoteUser, deleteUser } from './actions'
import { toast } from 'sonner'
import { ConfirmationModal } from '@/components/ui/confirmation-modal'

export function UserActions({ 
  userId, 
  dbRole, 
  currentRole 
}: { 
  userId: string, 
  dbRole: string,
  currentRole: string 
}) {
  const router = useRouter()
  const [loading, setLoading] = useState(false)
  const [showApproveModal, setShowApproveModal] = useState(false)
  const [showDemoteModal, setShowDemoteModal] = useState(false)
  const [showDeleteModal, setShowDeleteModal] = useState(false)

  const isSuperAdmin = currentRole === 'superadmin'

  async function handleApprove() {
    setLoading(true)
    const error = await approveAdmin(userId)
    setLoading(false)
    setShowApproveModal(false)

    if (error) {
      toast.error(error)
    } else {
      toast.success('Admin yetkisi verildi!')
      router.refresh()
    }
  }

  async function handleDemote() {
    setLoading(true)
    const error = await demoteUser(userId)
    setLoading(false)
    setShowDemoteModal(false)

    if (error) {
      toast.error(error)
    } else {
      toast.success('Admin yetkisi kaldırıldı.')
      router.refresh()
    }
  }

  async function handleDelete() {
    setLoading(true)
    const error = await deleteUser(userId)
    setLoading(false)
    setShowDeleteModal(false)

    if (error) {
      toast.error(error)
    } else {
      toast.success('Kullanıcı silindi.')
      router.refresh()
    }
  }

  return (
    <div className="flex items-center justify-end gap-2">
      {/* Yetkilendirme (Sadece Süperadmin) */}
      {isSuperAdmin && dbRole !== 'admin' && dbRole !== 'superadmin' && (
        <>
          <button
            onClick={() => setShowApproveModal(true)}
            disabled={loading}
            className="px-3 py-1.5 bg-semantic-success text-white rounded-md text-xs font-bold shadow-sm hover:opacity-90 transition-opacity disabled:opacity-50"
          >
            Yetkilendir
          </button>
          
          <ConfirmationModal
            isOpen={showApproveModal}
            onClose={() => setShowApproveModal(false)}
            onConfirm={handleApprove}
            title="Admin Yetkilendirme"
            message="Bu kullanıcıya admin yetkisini vermek istediğinize emin misiniz?"
            confirmText="Yetkilendir"
            variant="success"
            isLoading={loading}
          />
        </>
      )}

      {/* Yetki Kaldırma (Sadece Süperadmin) */}
      {isSuperAdmin && dbRole === 'admin' && (
        <>
          <button
            onClick={() => setShowDemoteModal(true)}
            disabled={loading}
            className="px-3 py-1.5 bg-brand-primary text-white rounded-md text-xs font-bold shadow-sm hover:opacity-90 transition-opacity disabled:opacity-50"
          >
            Yetki Kaldır
          </button>
          
          <ConfirmationModal
            isOpen={showDemoteModal}
            onClose={() => setShowDemoteModal(false)}
            onConfirm={handleDemote}
            title="Yetki Kaldırma"
            message="Bu kullanıcının admin yetkisini kaldırmak istediğinize emin misiniz? Kullanıcı öğrenci statüsüne dönecektir."
            confirmText="Yetkiyi Kaldır"
            variant="danger"
            isLoading={loading}
          />
        </>
      )}

      {/* Silme (Sadece Süperadmin) */}
      {isSuperAdmin && dbRole !== 'superadmin' && (
        <>
          <button
            onClick={() => setShowDeleteModal(true)}
            disabled={loading}
            className="px-3 py-1.5 bg-semantic-error/10 text-semantic-error rounded-md text-xs font-bold hover:bg-semantic-error hover:text-white transition-colors disabled:opacity-50"
          >
            Sil
          </button>

          <ConfirmationModal
            isOpen={showDeleteModal}
            onClose={() => setShowDeleteModal(false)}
            onConfirm={handleDelete}
            title="Kullanıcıyı Sil"
            message="Bu kullanıcıyı silmek istediğinize emin misiniz? Bu işlem geri alınamaz."
            confirmText="Kalıcı Olarak Sil"
            variant="danger"
            isLoading={loading}
          />
        </>
      )}

      {!isSuperAdmin && (
        <span className="text-[10px] text-ink-disabled italic">İşlem yetkiniz yok</span>
      )}
    </div>
  )
}
