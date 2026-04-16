// components/questions/approve-button.tsx
'use client'

import { useTransition } from 'react'
import { toast } from 'sonner'
import { approveQuestion } from '@/lib/actions/question-actions'

interface ApproveButtonProps {
  questionId: string
  disabled?: boolean
}

export function ApproveButton({ questionId, disabled }: ApproveButtonProps) {
  const [isPending, startTransition] = useTransition()

  function handleApprove() {
    startTransition(async () => {
      try {
        const result = await approveQuestion(questionId)
        toast.success(result.message)
      } catch (err: any) {
        toast.error(err.message ?? 'Onaylama sırasında bir hata oluştu')
      }
    })
  }

  return (
    <button
      onClick={handleApprove}
      disabled={isPending || disabled}
      title="Onayla"
      className={`
        inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold
        transition-all duration-200 border shrink-0
        ${isPending
          ? 'bg-semantic-success/10 text-semantic-success border-semantic-success/20 opacity-60 cursor-wait'
          : 'bg-semantic-success/10 text-semantic-success border-semantic-success/20 hover:bg-semantic-success hover:text-white hover:border-semantic-success hover:shadow-md hover:shadow-semantic-success/20 active:scale-95'
        }
        disabled:opacity-40 disabled:cursor-not-allowed
      `}
    >
      {isPending ? (
        <>
          <span className="animate-spin text-[10px]">⏳</span>
          <span>Onaylanıyor</span>
        </>
      ) : (
        <>
          <span>✓</span>
          <span>Onayla</span>
        </>
      )}
    </button>
  )
}
