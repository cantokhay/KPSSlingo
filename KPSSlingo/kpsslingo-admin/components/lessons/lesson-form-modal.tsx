// components/lessons/lesson-form-modal.tsx
'use client'

import { useState, useTransition, useEffect, useRef } from 'react'
import { toast } from 'sonner'
import { createLesson, updateLesson, type LessonPayload } from '@/lib/actions/lessons'

interface Topic {
  id: string
  title: string
}

interface LessonData {
  id: string
  title: string
  topic_id: string
  difficulty: 'beginner' | 'intermediate' | 'advanced'
  order: number
  description: string | null
  xp_reward: number
  status: 'draft' | 'published' | 'archived'
}

interface LessonFormModalProps {
  topics: Topic[]
  lesson?: LessonData      // Varsa → düzenleme modu
  defaultTopicId?: string  // Filtreden gelen ön seçim
  trigger: React.ReactNode
}

const DIFFICULTY_LABELS = {
  beginner:     { label: 'Başlangıç',  color: 'text-semantic-success' },
  intermediate: { label: 'Orta',       color: 'text-semantic-warning' },
  advanced:     { label: 'İleri',      color: 'text-semantic-error'   },
}

const STATUS_LABELS = {
  draft:     'Taslak',
  published: 'Yayında',
  archived:  'Arşivlendi',
}

export function LessonFormModal({ topics, lesson, defaultTopicId, trigger }: LessonFormModalProps) {
  const [open, setOpen] = useState(false)
  const [isPending, startTransition] = useTransition()
  const dialogRef = useRef<HTMLDialogElement>(null)

  const isEdit = !!lesson

  const [form, setForm] = useState<LessonPayload>({
    title:       lesson?.title       ?? '',
    topic_id:    lesson?.topic_id    ?? defaultTopicId ?? (topics[0]?.id ?? ''),
    difficulty:  lesson?.difficulty  ?? 'beginner',
    order:       lesson?.order       ?? 1,
    description: lesson?.description ?? '',
    xp_reward:   lesson?.xp_reward   ?? 10,
    status:      lesson?.status      ?? 'draft',
  })

  useEffect(() => {
    if (open) dialogRef.current?.showModal()
    else dialogRef.current?.close()
  }, [open])

  function handleField<K extends keyof LessonPayload>(key: K, value: LessonPayload[K]) {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()

    if (!form.title.trim()) { toast.error('Başlık zorunludur.'); return }
    if (!form.topic_id)      { toast.error('Konu seçimi zorunludur.'); return }

    startTransition(async () => {
      try {
        let result
        if (isEdit) {
          result = await updateLesson(lesson!.id, form)
        } else {
          result = await createLesson(form)
        }
        
        toast.success(result.message)
        setOpen(false)
        
        if (!isEdit) {
          setForm({
            title: '', topic_id: defaultTopicId ?? topics[0]?.id ?? '',
            difficulty: 'beginner', order: 1, description: '', xp_reward: 10, status: 'draft',
          })
        }
      } catch (err: any) {
        toast.error(err.message ?? 'Beklenmeyen bir hata oluştu.')
      }
    })
  }

  return (
    <>
      <span onClick={() => setOpen(true)} className="cursor-pointer">
        {trigger}
      </span>

      {open && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm animate-in fade-in duration-200"
          onClick={(e) => { if (e.target === e.currentTarget) setOpen(false) }}
        >
          <div className="w-full max-w-lg bg-white dark:bg-gray-900 rounded-[28px] shadow-2xl border border-slate-200 dark:border-gray-800 animate-in zoom-in-95 duration-200 overflow-hidden">
            <div className="flex items-center justify-between px-8 pt-7 pb-5 border-b border-slate-100 dark:border-gray-800">
              <div>
                <h2 className="text-xl font-extrabold text-ink-primary dark:text-gray-100 tracking-tight">
                  {isEdit ? '✏️ Dersi Düzenle' : '➕ Yeni Ders Ekle'}
                </h2>
                <p className="text-xs text-ink-secondary dark:text-gray-400 mt-0.5 font-medium">
                  {isEdit ? `"${lesson!.title}" dersini düzenliyorsunuz.` : 'Müfredata yeni bir ders ekleyin.'}
                </p>
              </div>
              <button
                onClick={() => setOpen(false)}
                className="w-9 h-9 flex items-center justify-center rounded-xl bg-slate-100 dark:bg-gray-800 text-ink-secondary hover:bg-semantic-error/10 hover:text-semantic-error transition-all duration-200 text-lg font-bold"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleSubmit} className="px-8 py-6 space-y-5">
              <div>
                <label className="block text-[11px] font-bold text-ink-secondary dark:text-gray-400 uppercase tracking-widest mb-1.5">
                  Ders Başlığı <span className="text-semantic-error">*</span>
                </label>
                <input
                  type="text"
                  value={form.title}
                  onChange={(e) => handleField('title', e.target.value)}
                  placeholder="ör. Türkçe — Fiil Çekimleri"
                  className="w-full bg-slate-50 dark:bg-gray-800 border border-slate-200 dark:border-gray-700 rounded-2xl px-4 py-3
                             text-sm text-ink-primary dark:text-gray-100 focus:outline-none focus:border-brand-primary
                             focus:ring-4 focus:ring-brand-primary/10 transition-all font-medium placeholder:text-ink-disabled"
                  required
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-ink-secondary dark:text-gray-400 uppercase tracking-widest mb-1.5">
                  Konu <span className="text-semantic-error">*</span>
                </label>
                <select
                  value={form.topic_id}
                  onChange={(e) => handleField('topic_id', e.target.value)}
                  className="w-full bg-slate-50 dark:bg-gray-800 border border-slate-200 dark:border-gray-700 rounded-2xl px-4 py-3
                             text-sm text-ink-primary dark:text-gray-100 focus:outline-none focus:border-brand-primary
                             focus:ring-4 focus:ring-brand-primary/10 transition-all font-medium"
                >
                  {topics.map((t) => (
                    <option key={t.id} value={t.id}>{t.title}</option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-[11px] font-bold text-ink-secondary dark:text-gray-400 uppercase tracking-widest mb-1.5">
                    Zorluk
                  </label>
                  <select
                    value={form.difficulty}
                    onChange={(e) => handleField('difficulty', e.target.value as LessonPayload['difficulty'])}
                    className="w-full bg-slate-50 dark:bg-gray-800 border border-slate-200 dark:border-gray-700 rounded-2xl px-4 py-3
                               text-sm text-ink-primary dark:text-gray-100 focus:outline-none focus:border-brand-primary
                               focus:ring-4 focus:ring-brand-primary/10 transition-all font-medium"
                  >
                    {(Object.entries(DIFFICULTY_LABELS) as [LessonPayload['difficulty'], typeof DIFFICULTY_LABELS[keyof typeof DIFFICULTY_LABELS]][]).map(([val, meta]) => (
                      <option key={val} value={val}>{meta.label}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-[11px] font-bold text-ink-secondary dark:text-gray-400 uppercase tracking-widest mb-1.5">
                    Sıra (Order)
                  </label>
                  <input
                    type="number"
                    min={1}
                    value={form.order}
                    onChange={(e) => handleField('order', parseInt(e.target.value) || 1)}
                    className="w-full bg-slate-50 dark:bg-gray-800 border border-slate-200 dark:border-gray-700 rounded-2xl px-4 py-3
                               text-sm text-ink-primary dark:text-gray-100 focus:outline-none focus:border-brand-primary
                               focus:ring-4 focus:ring-brand-primary/10 transition-all font-medium"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-[11px] font-bold text-ink-secondary dark:text-gray-400 uppercase tracking-widest mb-1.5">
                    XP Ödülü
                  </label>
                  <input
                    type="number"
                    min={1}
                    max={100}
                    value={form.xp_reward}
                    onChange={(e) => handleField('xp_reward', parseInt(e.target.value) || 10)}
                    className="w-full bg-slate-50 dark:bg-gray-800 border border-slate-200 dark:border-gray-700 rounded-2xl px-4 py-3
                               text-sm text-ink-primary dark:text-gray-100 focus:outline-none focus:border-brand-primary
                               focus:ring-4 focus:ring-brand-primary/10 transition-all font-medium"
                  />
                </div>
                <div>
                  <label className="block text-[11px] font-bold text-ink-secondary dark:text-gray-400 uppercase tracking-widest mb-1.5">
                    Durum
                  </label>
                  <select
                    value={form.status}
                    onChange={(e) => handleField('status', e.target.value as LessonPayload['status'])}
                    className="w-full bg-slate-50 dark:bg-gray-800 border border-slate-200 dark:border-gray-700 rounded-2xl px-4 py-3
                               text-sm text-ink-primary dark:text-gray-100 focus:outline-none focus:border-brand-primary
                               focus:ring-4 focus:ring-brand-primary/10 transition-all font-medium"
                  >
                    {(Object.entries(STATUS_LABELS) as [LessonPayload['status'], string][]).map(([val, label]) => (
                      <option key={val} value={val}>{label}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-bold text-ink-secondary dark:text-gray-400 uppercase tracking-widest mb-1.5">
                  Açıklama <span className="text-ink-disabled font-normal">(Opsiyonel)</span>
                </label>
                <textarea
                  value={form.description ?? ''}
                  onChange={(e) => handleField('description', e.target.value)}
                  placeholder="Ders hakkında kısa bir açıklama..."
                  rows={2}
                  className="w-full bg-slate-50 dark:bg-gray-800 border border-slate-200 dark:border-gray-700 rounded-2xl px-4 py-3
                             text-sm text-ink-primary dark:text-gray-100 focus:outline-none focus:border-brand-primary
                             focus:ring-4 focus:ring-brand-primary/10 transition-all font-medium resize-none placeholder:text-ink-disabled"
                />
              </div>

              <div className="flex items-center gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setOpen(false)}
                  className="flex-1 py-3 rounded-2xl text-sm font-bold text-ink-secondary dark:text-gray-400
                             bg-slate-100 dark:bg-gray-800 border border-slate-200 dark:border-gray-700
                             hover:bg-slate-200 dark:hover:bg-gray-700 transition-all duration-200"
                >
                  İptal
                </button>
                <button
                  type="submit"
                  disabled={isPending}
                  className="flex-1 py-3 rounded-2xl text-sm font-bold text-white
                             bg-brand-primary hover:bg-brand-light disabled:opacity-50
                             shadow-lg shadow-brand-primary/25 hover:shadow-brand-primary/40
                             hover:-translate-y-0.5 active:translate-y-0 transition-all duration-200
                             flex items-center justify-center gap-2"
                >
                  {isPending ? (
                    <><span className="animate-spin text-[10px]">⏳</span><span>Kaydediliyor...</span></>
                  ) : (
                    isEdit ? '💾 Güncelle' : '➕ Ders Ekle'
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  )
}
