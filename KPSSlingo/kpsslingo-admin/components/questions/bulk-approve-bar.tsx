// components/questions/bulk-approve-bar.tsx
'use client'

import { useState, useTransition } from 'react'
import { toast } from 'sonner'
import { bulkApproveQuestions } from '@/lib/actions/question-actions'

interface Question {
  id: string
  body: string
  status: string
  created_at: string
  source: string
  ai_review_score: number | null
  explanation: string | null
  lessons?: {
    title: string
    topics?: {
      title: string
    }
  }
  question_options: {
    label: string
    body: string
  }[]
}

interface BulkApproveBarProps {
  questions: Question[]
}

export function BulkApproveBar({ questions }: BulkApproveBarProps) {
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())
  const [isPending, startTransition] = useTransition()

  // Sadece draft/draft_flagged olanlar seçilebilir
  const approvableQuestions = questions.filter(
    (q) => q.status === 'draft' || q.status === 'draft_flagged'
  )
  const allSelected =
    approvableQuestions.length > 0 &&
    approvableQuestions.every((q) => selectedIds.has(q.id))

  function toggleAll() {
    if (allSelected) {
      setSelectedIds(new Set())
    } else {
      setSelectedIds(new Set(approvableQuestions.map((q) => q.id)))
    }
  }

  function toggleOne(id: string) {
    setSelectedIds((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  function handleBulkApprove() {
    const ids = Array.from(selectedIds)
    if (ids.length === 0) return

    startTransition(async () => {
      try {
        const result = await bulkApproveQuestions(ids)
        setSelectedIds(new Set())
        toast.success(result.message)
      } catch (err: any) {
        toast.error(err.message ?? 'Toplu onaylama başarısız oldu')
      }
    })
  }

  return (
    <div className="space-y-3">
      {/* Toplu işlem bar'ı */}
      <div className="flex items-center gap-3 bg-surface border border-ink-disabled/10 rounded-2xl px-4 py-3 sticky top-4 z-20 shadow-sm transition-colors">
        {/* Tümünü seç checkbox */}
        <div 
          onClick={toggleAll}
          className="flex items-center gap-2 cursor-pointer select-none group"
        >
          <div
            className={`
              w-5 h-5 rounded-md border-2 flex items-center justify-center transition-all duration-200
              ${allSelected
                ? 'bg-brand-primary border-brand-primary'
                : 'border-ink-disabled/30 group-hover:border-brand-primary/60'
              }
            `}
          >
            {allSelected && <span className="text-white text-[10px] font-black">✓</span>}
            {!allSelected && selectedIds.size > 0 && (
              <span className="text-brand-primary text-[10px] font-black">–</span>
            )}
          </div>
          <span className="text-xs font-bold text-ink-secondary">
            Tümünü Seç
            {approvableQuestions.length > 0 && (
              <span className="ml-1 text-ink-disabled">
                ({approvableQuestions.length})
              </span>
            )}
          </span>
        </div>

        {/* Seçim sayısı + Onayla butonu */}
        <div className="flex-1" />

        {selectedIds.size > 0 && (
          <div className="flex items-center gap-2 animate-in slide-in-from-right-2 duration-200">
            <span className="text-xs font-bold text-ink-secondary">
              {selectedIds.size} soru seçildi
            </span>
            <button
              onClick={handleBulkApprove}
              disabled={isPending}
              className={`
                flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold
                transition-all duration-200
                ${isPending
                  ? 'bg-semantic-success/60 text-white cursor-wait'
                  : 'bg-semantic-success text-white hover:shadow-lg hover:shadow-semantic-success/25 active:scale-95'
                }
              `}
            >
              {isPending ? (
                <>
                  <span className="animate-spin text-[10px]">⏳</span>
                  <span>Onaylanıyor...</span>
                </>
              ) : (
                <>
                  <span>✓</span>
                  <span>Seçilenleri Onayla ({selectedIds.size})</span>
                </>
              )}
            </button>
          </div>
        )}
      </div>

      {/* Soru listesi — her biri checkbox ile */}
      <BulkQuestionListView
        questions={questions}
        selectedIds={selectedIds}
        toggleOne={toggleOne}
      />
    </div>
  )
}

// ─── Soru listesi (checkbox + bilgi + aksiyon) ────────────────────────────────
import Link from 'next/link'
import { ApproveButton } from './approve-button'
import { ScoreBadge } from './score-badge'
import { QuestionPreviewPopover } from './question-preview-popover'

function BulkQuestionListView({
  questions,
  selectedIds,
  toggleOne,
}: {
  questions: Question[]
  selectedIds: Set<string>
  toggleOne: (id: string) => void
}) {
  if (questions.length === 0) {
    return (
      <div className="text-center py-20 bg-surface rounded-[32px] border border-dashed border-ink-disabled/20">
        <div className="text-4xl mb-4">🔍</div>
        <p className="text-ink-secondary font-bold">Bu kategoride gösterilecek soru bulunamadı.</p>
        <p className="text-ink-disabled text-sm mt-1">Filtreleri değiştirmeyi veya yeni soru üretmeyi deneyin.</p>
      </div>
    )
  }

  return (
    <div className="grid gap-3">
      {questions.map((q) => {
        const isApprovable = q.status === 'draft' || q.status === 'draft_flagged'
        const isSelected = selectedIds.has(q.id)

        return (
          <div
            key={q.id}
            className={`
              bg-surface border rounded-[20px] p-4
              flex items-center gap-4 group
              hover:border-brand-primary/30 hover:shadow-lg hover:shadow-brand-primary/5
              transition-all duration-300
              ${isSelected
                ? 'border-brand-primary/40 bg-brand-primary/[0.02] shadow-sm shadow-brand-primary/10'
                : 'border-ink-disabled/10'
              }
            `}
          >
            {/* Checkbox */}
            <div
              onClick={() => isApprovable && toggleOne(q.id)}
              className={`
                w-5 h-5 rounded-md border-2 flex items-center justify-center shrink-0
                transition-all duration-200
                ${isApprovable ? 'cursor-pointer' : 'cursor-default opacity-30'}
                ${isSelected
                  ? 'bg-brand-primary border-brand-primary'
                  : 'border-ink-disabled/30 hover:border-brand-primary/60'
                }
              `}
            >
              {isSelected && <span className="text-white text-[10px] font-black">✓</span>}
            </div>

            {/* Bilgi */}
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-1.5">
                <span className="text-[10px] font-bold text-brand-primary bg-brand-primary/5 px-2 py-0.5 rounded-full uppercase tracking-wider">
                  {q.lessons?.topics?.title}
                </span>
                <span className="text-[10px] font-bold text-ink-secondary bg-surface-muted px-2 py-0.5 rounded-full uppercase tracking-wider">
                  {q.lessons?.title}
                </span>
                {q.status === 'draft_flagged' && (
                  <span className="text-[10px] font-extrabold text-[#D97706] bg-[#FEF3C7] dark:bg-yellow-900/30 px-2 py-0.5 rounded-full uppercase tracking-wider border border-[#FCD34D]">
                    ⚠ AI DİKKAT
                  </span>
                )}
                {q.status === 'published' && (
                  <span className="text-[10px] font-extrabold text-semantic-success bg-semantic-success/10 px-2 py-0.5 rounded-full uppercase tracking-wider">
                    ✓ Yayınlandı
                  </span>
                )}
                <ScoreBadge score={q.ai_review_score} />
              </div>

              <h3 className="text-sm font-semibold text-ink-primary line-clamp-2 leading-relaxed">
                {q.body}
              </h3>

              <div className="flex items-center gap-4 mt-2 text-[11px] font-bold text-ink-disabled uppercase tracking-widest">
                <span>{new Date(q.created_at).toLocaleDateString('tr-TR')}</span>
                <span className="w-1 h-1 bg-ink-disabled/30 rounded-full" />
                <span>{q.source === 'ai_generated' ? '🤖 AI Üretimi' : '✍️ Manuel'}</span>
              </div>
            </div>

            {/* Aksiyon butonları */}
            <div className="shrink-0 flex items-center gap-2">
              <QuestionPreviewPopover
                body={q.body}
                explanation={q.explanation}
                options={q.question_options}
                trigger={
                  <button
                    title="Önizle"
                    className="inline-flex items-center justify-center w-10 h-10 rounded-xl
                               bg-surface-alt border border-ink-disabled/10 text-ink-secondary
                               hover:bg-surface-muted transition-all duration-200 shadow-sm"
                  >
                    <span className="text-sm">👁️</span>
                  </button>
                }
              />

              {isApprovable && (
                <ApproveButton questionId={q.id} />
              )}

              <Link
                href={`/dashboard/questions/${q.id}`}
                className="inline-flex items-center justify-center w-10 h-10 rounded-xl
                           bg-surface-alt border border-ink-disabled/10 text-brand-primary
                           group-hover:bg-brand-primary group-hover:text-white
                           group-hover:border-brand-primary transition-all duration-300 shadow-sm"
              >
                <span className="text-sm font-bold">→</span>
              </Link>
            </div>
          </div>
        )
      })}
    </div>
  )
}
