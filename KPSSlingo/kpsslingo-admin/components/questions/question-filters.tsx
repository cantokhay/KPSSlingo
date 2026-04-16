// components/questions/question-filters.tsx
'use client'

import { useRouter, useSearchParams } from 'next/navigation'

const statuses = [
  { value: 'draft',     label: 'Bekleyenler' },
  { value: 'published', label: 'Yayındakiler' },
  { value: 'archived',  label: 'Arşivlenenler' },
  { value: 'all',       label: 'Tümü' },
]

interface Topic {
  id: string
  title: string
}

interface Lesson {
  id: string
  title: string
  topic_id: string
}

interface QuestionFiltersProps {
  currentStatus: string
  topics: Topic[]
  lessons: Lesson[]
}

export function QuestionFilters({ currentStatus, topics, lessons }: QuestionFiltersProps) {
  const router = useRouter()
  const searchParams = useSearchParams()

  const currentTopic  = searchParams.get('topic')    ?? ''
  const currentLesson = searchParams.get('lesson')   ?? ''
  const minScore      = searchParams.get('minScore') ?? ''

  function updateParam(key: string, value: string) {
    const params = new URLSearchParams(searchParams.toString())
    if (value) params.set(key, value)
    else params.delete(key)
    params.set('page', '1')

    // Konu değişince ders filtresini sıfırla
    if (key === 'topic') params.delete('lesson')

    router.push(`/dashboard/questions?${params.toString()}`)
  }

  // Seçili konuya göre ders listesini filtrele
  const filteredLessons = currentTopic
    ? lessons.filter((l) => l.topic_id === currentTopic)
    : lessons

  return (
    <div className="flex flex-wrap items-center gap-2 p-1">
      {/* Status pill'leri */}
      <div className="flex items-center gap-1.5 overflow-x-auto">
        {statuses.map((s) => (
          <button
            key={s.value}
            onClick={() => updateParam('status', s.value)}
            className={`
              px-4 py-2 rounded-pill text-xs font-bold whitespace-nowrap transition-all duration-200
              ${currentStatus === s.value
                ? 'bg-brand-primary text-white shadow-md shadow-brand-primary/20'
                : 'bg-surface border border-ink-disabled/10 text-ink-secondary hover:border-brand-primary/40'
              }
            `}
          >
            {s.label}
          </button>
        ))}
      </div>

      {/* Ayraç */}
      <div className="w-px h-6 bg-ink-disabled/20 mx-1" />

      {/* Konu dropdown */}
      <div className="relative">
        <select
          value={currentTopic}
          onChange={(e) => updateParam('topic', e.target.value)}
          className={`
            appearance-none pl-3 pr-8 py-2 rounded-xl text-xs font-bold border transition-all duration-200
            bg-surface cursor-pointer focus:outline-none focus:ring-2 focus:ring-brand-primary/20
            ${currentTopic
              ? 'border-brand-primary text-brand-primary'
              : 'border-ink-disabled/10 text-ink-secondary hover:border-brand-primary/40'
            }
          `}
        >
          <option value="">🗂️ Tüm Konular</option>
          {topics.map((t) => (
            <option key={t.id} value={t.id}>{t.title}</option>
          ))}
        </select>
        <span className="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 text-[10px] text-ink-disabled">▼</span>
      </div>

      {/* Ders dropdown */}
      <div className="relative">
        <select
          value={currentLesson}
          onChange={(e) => updateParam('lesson', e.target.value)}
          disabled={filteredLessons.length === 0}
          className={`
            appearance-none pl-3 pr-8 py-2 rounded-xl text-xs font-bold border transition-all duration-200
            bg-surface cursor-pointer focus:outline-none focus:ring-2 focus:ring-brand-primary/20
            disabled:opacity-40 disabled:cursor-not-allowed
            ${currentLesson
              ? 'border-brand-primary text-brand-primary'
              : 'border-ink-disabled/10 text-ink-secondary hover:border-brand-primary/40'
            }
          `}
        >
          <option value="">📚 Tüm Dersler</option>
          {filteredLessons.map((l) => (
            <option key={l.id} value={l.id}>{l.title}</option>
          ))}
        </select>
        <span className="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 text-[10px] text-ink-disabled">▼</span>
      </div>

      {/* Min Skor dropdown */}
      <div className="relative">
        <select
          value={minScore}
          onChange={(e) => updateParam('minScore', e.target.value)}
          className={`
            appearance-none pl-3 pr-8 py-2 rounded-xl text-xs font-bold border transition-all duration-200
            bg-surface cursor-pointer focus:outline-none focus:ring-2 focus:ring-brand-primary/20
            ${minScore
              ? 'border-brand-primary text-brand-primary'
              : 'border-ink-disabled/10 text-ink-secondary hover:border-brand-primary/40'
            }
          `}
        >
          <option value="">⭐ Tüm Skorlar</option>
          <option value="8">⭐⭐⭐ 8+ (Yüksek)</option>
          <option value="6">⭐⭐ 6+ (Orta)</option>
          <option value="4">⭐ 4+ (Düşük)</option>
        </select>
        <span className="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 text-[10px] text-ink-disabled">▼</span>
      </div>

      {/* Aktif filtre göstergesi + temizle */}
      {(currentTopic || currentLesson || minScore) && (
        <button
          onClick={() => {
            const params = new URLSearchParams(searchParams.toString())
            params.delete('topic')
            params.delete('lesson')
            params.delete('minScore')
            params.set('page', '1')
            router.push(`/dashboard/questions?${params.toString()}`)
          }}
          className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold
                     text-semantic-error bg-semantic-error/10 border border-semantic-error/20
                     hover:bg-semantic-error hover:text-white transition-all duration-200"
        >
          <span>✕</span>
          <span>Filtreyi Temizle</span>
        </button>
      )}
    </div>
  )
}
