'use client'

import { useState, useTransition } from 'react'
import { rejectQuestionWithReason } from '@/lib/actions/question-actions'

const REJECTION_REASONS = [
  { code: 'factually_wrong',    label: 'Faktüel Hata' },
  { code: 'ambiguous_question', label: 'Belirsiz Soru' },
  { code: 'multiple_correct',   label: 'Birden Fazla Doğru' },
  { code: 'wrong_difficulty',   label: 'Yanlış Zorluk' },
  { code: 'off_curriculum',     label: 'Müfredat Dışı' },
  { code: 'poor_distractors',   label: 'Zayıf Çeldiriciler' },
  { code: 'language_quality',   label: 'Dil Kalitesi' },
  { code: 'other',              label: 'Diğer' },
]

export function RejectModal({
  questionId,
  lessonId,
  onClose,
}: {
  questionId: string
  lessonId: string
  onClose: () => void
}) {
  const [selectedReason, setSelectedReason] = useState('')
  const [adminNote, setAdminNote]           = useState('')
  const [isPending, startTransition]        = useTransition()

  function handleReject() {
    if (!selectedReason) return
    startTransition(async () => {
      try {
        await rejectQuestionWithReason(questionId, lessonId, selectedReason, adminNote)
        onClose()
      } catch (err) {
        alert(String(err))
      }
    })
  }

  return (
    <div className="fixed inset-0 bg-ink-primary/40 backdrop-blur-sm z-50 flex items-center
                    justify-center p-4">
      <div className="bg-surface rounded-[24px] border border-slate-200 w-full max-w-md p-8 shadow-2xl animate-in fade-in zoom-in-95 duration-300">
        <h3 className="text-xl font-black text-ink-primary mb-2 tracking-tight">
          Soruyu Reddet
        </h3>
        <p className="text-sm font-medium text-ink-secondary mb-6 opacity-70">
          Lütfen reddetme sebebini seçin. Bu bilgi yeniden üretimde AI'ya iletilecektir.
        </p>

        {/* Neden seçimi — zorunlu */}
        <div className="mb-6">
          <label className="text-[11px] font-black text-ink-disabled uppercase tracking-widest block mb-3">
            Reddetme Nedeni <span className="text-semantic-error">*</span>
          </label>
          <div className="grid grid-cols-1 gap-2 max-h-[240px] overflow-y-auto pr-2 custom-scrollbar">
            {REJECTION_REASONS.map((r) => (
              <label 
                key={r.code} 
                className={`
                    flex items-center gap-3 p-3 rounded-xl border transition-all cursor-pointer
                    ${selectedReason === r.code 
                        ? 'bg-brand-primary/5 border-brand-primary/30 text-brand-primary' 
                        : 'bg-white border-slate-100 text-ink-secondary hover:border-slate-200'
                    }
                `}
              >
                <input
                  type="radio"
                  name="reason"
                  value={r.code}
                  checked={selectedReason === r.code}
                  onChange={() => setSelectedReason(r.code)}
                  className="hidden"
                />
                <span className={`w-4 h-4 rounded-full border-2 flex items-center justify-center shrink-0
                                 ${selectedReason === r.code ? 'border-brand-primary' : 'border-slate-300'}`}>
                    {selectedReason === r.code && <span className="w-2 h-2 bg-brand-primary rounded-full" />}
                </span>
                <span className="text-sm font-bold">{r.label}</span>
              </label>
            ))}
          </div>
        </div>

        {/* Opsiyonel admin notu */}
        <div className="mb-8">
          <label className="text-[11px] font-black text-ink-disabled uppercase tracking-widest block mb-2">
            Ek Not (opsiyonel)
          </label>
          <textarea
            value={adminNote}
            onChange={(e) => setAdminNote(e.target.value)}
            placeholder="AI'ya spesifik talimat bırakın..."
            rows={3}
            className="w-full border border-slate-200 rounded-2xl px-4 py-3
                       text-sm font-semibold text-ink-primary resize-none placeholder:text-ink-disabled/60
                       focus:outline-none focus:border-brand-primary focus:ring-4 focus:ring-brand-primary/5 transition-all"
          />
        </div>

        <div className="flex gap-4">
          <button
            onClick={onClose}
            disabled={isPending}
            className="flex-1 py-4 text-sm font-black text-ink-secondary
                       bg-surface-muted rounded-2xl hover:bg-slate-200 transition-colors"
          >
            İPTAL
          </button>
          <button
            onClick={handleReject}
            disabled={!selectedReason || isPending}
            className="flex-1 py-4 text-sm font-black text-white bg-semantic-error
                       rounded-2xl hover:opacity-90 transition-all shadow-lg shadow-semantic-error/20
                       disabled:opacity-40 disabled:cursor-not-allowed disabled:shadow-none"
          >
            {isPending ? 'KAYDEDİLİYOR...' : 'REDDET VE YENİLE'}
          </button>
        </div>
      </div>
    </div>
  )
}
