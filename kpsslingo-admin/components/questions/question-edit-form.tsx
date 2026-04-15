// components/questions/question-edit-form.tsx
'use client'

import { useState, useTransition, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { approveQuestion, updateQuestion } from '@/lib/actions/question-actions'
import { RejectModal } from './reject-modal'
import type { Question, QuestionOption } from '@/lib/types'

export function QuestionEditForm({ question }: { question: Question }) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()

  // Local state for editing
  const [body, setBody] = useState(question.body)
  const [explanation, setExplanation] = useState(question.explanation ?? '')
  const [correctOption, setCorrectOption] = useState(question.correct_option)
  const [options, setOptions] = useState<QuestionOption[]>(
    [... (question.question_options ?? [])].sort((a, b) => a.label.localeCompare(b.label))
  )
  const [isRejectModalOpen, setIsRejectModalOpen] = useState(false)

  // Track if there are changes
  const [hasChanges, setHasChanges] = useState(false)

  useEffect(() => {
    const isBodyChanged = body !== question.body
    const isExplanationChanged = explanation !== (question.explanation ?? '')
    const isCorrectChanged = correctOption !== question.correct_option
    const areOptionsChanged = options.some((opt, i) => {
        const original = question.question_options?.find(o => o.label === opt.label)
        return opt.body !== original?.body
    })
    setHasChanges(isBodyChanged || isExplanationChanged || isCorrectChanged || areOptionsChanged)
  }, [body, explanation, correctOption, options, question])

  function updateOption(label: string, value: string) {
    setOptions((prev) =>
      prev.map((o) => (o.label === label ? { ...o, body: value } : o))
    )
  }

  async function handleSaveAndApprove() {
    startTransition(async () => {
      try {
        // First update if there are changes or if just publishing
        await updateQuestion(question.id, {
          body,
          explanation,
          correct_option: correctOption,
          options: options.map((o) => ({ label: o.label, body: o.body })),
        })
        
        // Then approve if it's currently draft or flagged
        if (question.status === 'draft' || question.status === 'draft_flagged') {
            await approveQuestion(question.id)
        }
        
        router.refresh()
        router.push('/dashboard/questions')
      } catch (error: any) {
        alert("Hata: " + error.message)
      }
    })
  }

  function handleRejectClick() {
    setIsRejectModalOpen(true)
  }

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-2 duration-500">
      {/* Question Text */}
      <section className="bg-surface rounded-card border border-slate-200 p-6 shadow-sm">
        <label className="block text-xs font-bold text-ink-secondary uppercase tracking-widest mb-4">
          Soru Metni
        </label>
        <textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          rows={5}
          className="w-full bg-surface-alt border border-slate-200 rounded-card px-4 py-4
                     text-sm text-ink-primary font-mono leading-relaxed resize-none
                     focus:outline-none focus:border-brand-primary focus:ring-4
                     focus:ring-brand-primary/10 transition-all"
        />
      </section>

      {/* Options */}
      <section className="bg-surface rounded-card border border-slate-200 p-6 shadow-sm">
        <div className="flex items-center justify-between mb-6">
          <label className="text-xs font-bold text-ink-secondary uppercase tracking-widest">
            Seçenekler
          </label>
          <div className="flex items-center gap-3 bg-surface-muted px-3 py-1.5 rounded-pill border border-slate-200">
            <span className="text-[10px] font-bold text-ink-secondary uppercase">Doğru Cevap:</span>
            <select
              value={correctOption}
              onChange={(e) => setCorrectOption(e.target.value)}
              className="text-sm font-bold text-brand-primary bg-transparent focus:outline-none appearance-none"
            >
              {['A', 'B', 'C', 'D', 'E'].map((l) => (
                <option key={l} value={l}>{l}</option>
              ))}
            </select>
            <span className="text-brand-primary text-[10px]">▼</span>
          </div>
        </div>

        <div className="grid gap-3">
          {options.map((option) => (
            <div key={option.label} className="flex items-center gap-4 group">
              <span className={`
                w-10 h-10 flex items-center justify-center rounded-full text-sm font-bold shrink-0
                transition-all duration-300 border-2
                ${option.label === correctOption
                  ? 'bg-semantic-success text-white border-semantic-success shadow-sm'
                  : 'bg-surface-alt text-ink-secondary border-slate-200 group-hover:border-brand-primary/40'
                }
              `}>
                {option.label}
              </span>
              <input
                value={option.body}
                onChange={(e) => updateOption(option.label, e.target.value)}
                className="flex-1 bg-surface-alt border border-slate-200 rounded-card
                           px-4 py-3 text-sm text-ink-primary
                           focus:outline-none focus:border-brand-primary focus:ring-4
                           focus:ring-brand-primary/10 transition-all"
              />
            </div>
          ))}
        </div>
      </section>

      {/* Explanation */}
      <section className="bg-surface rounded-card border border-slate-200 p-6 shadow-sm">
        <label className="block text-xs font-bold text-ink-secondary uppercase tracking-widest mb-4">
          Çözüm Açıklaması
        </label>
        <textarea
          value={explanation}
          onChange={(e) => setExplanation(e.target.value)}
          rows={3}
          placeholder="Bu sorunun çözümünü buraya yazın..."
          className="w-full bg-surface-alt border border-slate-200 rounded-card px-4 py-4
                     text-sm text-ink-primary leading-relaxed resize-none
                     focus:outline-none focus:border-brand-primary focus:ring-4
                     focus:ring-brand-primary/10 transition-all placeholder:text-ink-disabled"
        />
      </section>

      {/* Action Buttons */}
      <div className="flex items-center justify-between py-6 sticky bottom-0 bg-surface-alt/80 backdrop-blur-md -mx-4 px-4 z-10 border-t border-slate-200/50">
        <button
          onClick={handleRejectClick}
          disabled={isPending || question.status === 'archived' || question.status === 'ai_rejected'}
          className="px-6 py-3 text-sm font-bold text-semantic-error
                     bg-semantic-error/10 border border-semantic-error/20 rounded-card
                     hover:bg-semantic-error hover:text-white transition-all
                     disabled:opacity-20 disabled:grayscale cursor-pointer"
        >
          Reddet & Yeniden Üret
        </button>

        <div className="flex items-center gap-4">
            {hasChanges && (
                <span className="text-[10px] font-bold text-brand-accent animate-pulse">
                    KAYDEDİLMEMİŞ DEĞİŞİKLİKLER VAR
                </span>
            )}
            <button
            onClick={handleSaveAndApprove}
            disabled={isPending || (question.status === 'published' && !hasChanges)}
            className="px-8 py-3 text-sm font-bold text-white
                        bg-brand-primary rounded-card shadow-lg shadow-brand-primary/20
                        hover:bg-brand-light hover:-translate-y-0.5 transition-all
                        disabled:opacity-50 disabled:translate-y-0 disabled:shadow-none
                        flex items-center gap-3 cursor-pointer"
            >
            {isPending ? (
                <>
                <span className="animate-spin text-lg">⏳</span> İşleniyor...
                </>
            ) : (
                <>
                {['draft', 'draft_flagged'].includes(question.status) ? 'Kaydet & Onayla ✓' : 'Güncellemeleri Kaydet'}
                </>
            )}
            </button>
        </div>
      </div>

      {/* Status Info */}
      {question.status === 'published' && !hasChanges && (
        <div className="flex items-center justify-center gap-2 text-semantic-success py-2">
            <span className="text-sm font-bold">✓ Bu soru yayında ve güncel</span>
        </div>
      )}

      {/* Reject Modal */}
      {isRejectModalOpen && (
        <RejectModal
            questionId={question.id}
            lessonId={question.lesson_id}
            onClose={() => setIsRejectModalOpen(false)}
        />
      )}
    </div>
  )
}
