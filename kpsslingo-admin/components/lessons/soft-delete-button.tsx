// components/lessons/soft-delete-button.tsx
'use client'

import { useState, useTransition } from 'react'
import { toast } from 'sonner'
import { softDeleteLesson, restoreLesson } from '@/lib/actions/lessons'

interface SoftDeleteButtonProps {
  lessonId: string
  lessonTitle: string
  isArchived: boolean
}

export function SoftDeleteButton({ lessonId, lessonTitle, isArchived }: SoftDeleteButtonProps) {
  const [isPending, startTransition] = useTransition()
  const [confirming, setConfirming] = useState(false)

  function handleClick() {
    if (isArchived) {
      startTransition(async () => {
        try {
          const result = await restoreLesson(lessonId)
          toast.success(result.message)
        } catch (err: any) {
          toast.error(err.message ?? 'Geri yükleme başarısız oldu')
        }
      })
      return
    }
    setConfirming(true)
  }

  function confirmDelete() {
    setConfirming(false)
    startTransition(async () => {
      try {
        const result = await softDeleteLesson(lessonId)
        toast.success(result.message)
      } catch (err: any) {
        toast.error(err.message ?? 'Arşivleme başarısız oldu')
      }
    })
  }

  if (confirming) {
    return (
      <div className="flex items-center gap-1 animate-in fade-in duration-150">
        <span className="text-[10px] font-bold text-ink-secondary dark:text-gray-400 mr-1">Emin misiniz?</span>
        <button
          onClick={confirmDelete}
          className="px-2.5 py-1.5 rounded-lg text-[10px] font-bold bg-semantic-error text-white hover:opacity-80 transition-all shadow-sm shadow-semantic-error/20"
        >
          Evet
        </button>
        <button
          onClick={() => setConfirming(false)}
          className="px-2.5 py-1.5 rounded-lg text-[10px] font-bold bg-slate-100 dark:bg-gray-800 text-ink-secondary border border-slate-200 dark:border-gray-700 hover:bg-slate-200 transition-all"
        >
          Hayır
        </button>
      </div>
    )
  }

  return (
    <button
      onClick={handleClick}
      disabled={isPending}
      title={isArchived ? 'Dersi geri yükle' : `"${lessonTitle}" dersini pasife al`}
      className={`
        inline-flex items-center justify-center gap-1 px-3 py-1.5 rounded-xl text-[10px] font-bold
        border transition-all duration-200 disabled:opacity-40 disabled:cursor-not-allowed
        whitespace-nowrap min-w-[100px]
        ${isArchived
          ? 'border-semantic-success/30 text-semantic-success bg-semantic-success/5 hover:bg-semantic-success hover:text-white hover:border-semantic-success'
          : 'border-semantic-error/30 text-semantic-error bg-semantic-error/5 hover:bg-semantic-error hover:text-white hover:border-semantic-error'
        }
      `}
    >
      {isPending ? (
        <span className="animate-spin text-[10px]">⏳</span>
      ) : isArchived ? (
        <><span>↩</span><span>Geri Al</span></>
      ) : (
        <><span>⊘</span><span>Pasife Al</span></>
      )}
    </button>
  )
}
