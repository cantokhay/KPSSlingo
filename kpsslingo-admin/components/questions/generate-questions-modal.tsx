// components/questions/generate-questions-modal.tsx
'use client'

import { useState, useTransition, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { generateQuestionsForLesson } from '@/lib/actions/generation-actions'
import { getTopics, getLessonsByTopic } from '@/lib/actions/data-actions'

export function GenerateQuestionsButton() {
  const router = useRouter()
  const [isOpen, setIsOpen] = useState(false)
  
  // Data lists
  const [topics, setTopics] = useState<any[]>([])
  const [lessons, setLessons] = useState<any[]>([])
  
  // Form selections
  const [selectedTopicId, setSelectedTopicId] = useState('')
  const [selectedLessonId, setSelectedLessonId] = useState('')
  const [count, setCount]                   = useState(10)
  
  const [result, setResult]           = useState<{ generated: number; errors: number } | null>(null)
  const [isPending, startTransition]  = useTransition()

  // Fetch topics on mount
  useEffect(() => {
    if (isOpen) {
      getTopics().then(setTopics)
    }
  }, [isOpen])

  // Fetch lessons when topic changes
  useEffect(() => {
    if (selectedTopicId) {
      getLessonsByTopic(selectedTopicId).then(setLessons)
      setSelectedLessonId('') // Reset lesson selection
    } else {
      setLessons([])
    }
  }, [selectedTopicId])

  function handleGenerate() {
    const topic = topics.find(t => t.id === selectedTopicId)
    const lesson = lessons.find(l => l.id === selectedLessonId)

    if (!selectedLessonId || !lesson || !topic) {
      alert("Lütfen bir ders seçin.")
      return
    }
    
    startTransition(async () => {
      try {
        const res = await generateQuestionsForLesson(
          selectedLessonId, 
          lesson.title, 
          topic.title, 
          count
        )
        setResult(res)
        router.refresh()
      } catch (error: any) {
        alert("Hata: " + error.message)
      }
    })
  }

  function handleClose() {
    setIsOpen(false)
    setResult(null)
    setSelectedTopicId('')
    setSelectedLessonId('')
  }

  return (
    <>
      <button
        onClick={() => setIsOpen(true)}
        className="flex items-center gap-2 bg-brand-accent text-white text-sm font-bold
                   px-5 py-2.5 rounded-card hover:bg-brand-accent/90 transition-all
                   shadow-lg shadow-brand-accent/20 active:scale-95 cursor-pointer"
      >
        <span>✨</span>
        <span>Soru Üret</span>
      </button>

      {isOpen && (
        <div className="fixed inset-0 bg-ink-primary/40 backdrop-blur-md z-[100] flex items-start justify-center p-4 pt-20 animate-in fade-in duration-200 overflow-y-auto">
          <div 
            className="bg-surface rounded-3xl border border-slate-200 w-full max-w-lg p-8 shadow-2xl animate-in zoom-in-95 duration-200"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-extrabold text-ink-primary">
                AI ile Soru Üret (Gemini)
              </h2>
              <button 
                onClick={handleClose}
                className="text-ink-secondary hover:text-ink-primary p-1"
              >
                ✕
              </button>
            </div>

            <div className="space-y-6">
              {/* Topic Selection */}
              <div>
                <label className="block text-[10px] font-bold text-ink-secondary uppercase tracking-widest mb-1.5">
                  Konu Seçiniz
                </label>
                <select
                  value={selectedTopicId}
                  onChange={(e) => setSelectedTopicId(e.target.value)}
                  className="w-full bg-surface-alt border border-slate-200 rounded-card px-4 py-3
                             text-sm font-medium focus:outline-none focus:border-brand-primary appearance-none cursor-pointer"
                >
                  <option value="">Konu Seçin...</option>
                  {topics.map(t => (
                    <option key={t.id} value={t.id}>{t.title}</option>
                  ))}
                </select>
              </div>

              {/* Lesson Selection */}
              <div className={!selectedTopicId ? 'opacity-40 pointer-events-none' : ''}>
                <label className="block text-[10px] font-bold text-ink-secondary uppercase tracking-widest mb-1.5">
                  Ders Seçiniz
                </label>
                <select
                  value={selectedLessonId}
                  onChange={(e) => setSelectedLessonId(e.target.value)}
                  className="w-full bg-surface-alt border border-slate-200 rounded-card px-4 py-3
                             text-sm font-medium focus:outline-none focus:border-brand-primary appearance-none cursor-pointer"
                  disabled={!selectedTopicId}
                >
                  <option value="">{lessons.length > 0 ? 'Ders Seçin...' : 'Önce Konu Seçin'}</option>
                  {lessons.map(l => (
                    <option key={l.id} value={l.id}>{l.title}</option>
                  ))}
                </select>
              </div>

              {/* Count */}
              <div>
                <label className="block text-[10px] font-bold text-ink-secondary uppercase tracking-widest mb-1.5">
                  Soru Sayısı
                </label>
                <div className="grid grid-cols-4 gap-2">
                  {[5, 10, 15, 20].map((n) => (
                    <button
                      key={n}
                      onClick={() => setCount(n)}
                      className={`
                        py-2 text-xs font-bold rounded-card border transition-all
                        ${count === n 
                          ? 'bg-brand-primary text-white border-brand-primary shadow-md' 
                          : 'bg-surface-alt border-slate-200 text-ink-secondary hover:border-brand-primary/40'}
                      `}
                    >
                      {n}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Results Display */}
            {result && (
              <div className={`mt-6 p-4 rounded-card border text-sm font-bold flex items-center gap-3 animate-in slide-in-from-top-2
                ${result.errors === 0
                  ? 'bg-semantic-success/10 text-semantic-success border-semantic-success/20'
                  : 'bg-semantic-warning/10 text-semantic-warning border-semantic-warning/20'
                }`}
              >
                <span>{result.errors === 0 ? '✅' : '⚠️'}</span>
                <div>
                    <p>{result.generated} soru başarıyla oluşturuldu.</p>
                    {result.errors > 0 && <p className="text-xs font-medium opacity-80">{result.errors} hata oluştu.</p>}
                </div>
              </div>
            )}

            {/* Footer Actions */}
            <div className="flex gap-4 mt-8">
              <button
                onClick={handleClose}
                className="flex-1 py-3 text-sm font-bold text-ink-secondary
                           bg-surface-alt border border-slate-200 rounded-card hover:bg-slate-200 transition-all font-sans"
              >
                {result ? 'Kapat' : 'İptal'}
              </button>
              {!result && (
                <button
                  onClick={handleGenerate}
                  disabled={isPending || !selectedLessonId}
                  className="flex-1 py-3 text-sm font-bold text-white bg-brand-primary
                             rounded-card shadow-lg shadow-brand-primary/20 hover:bg-brand-light transition-all
                             disabled:opacity-40 disabled:grayscale flex items-center justify-center"
                >
                  {isPending ? (
                    <span className="flex items-center gap-2">
                      <span className="animate-spin text-lg">⏳</span>
                      Üretiliyor...
                    </span>
                  ) : (
                    '✨ Üretimi Başlat'
                  )}
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  )
}
