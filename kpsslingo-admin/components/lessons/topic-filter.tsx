'use client'

import { useRouter, useSearchParams } from 'next/navigation'

interface Topic {
  id: string
  title: string
}

interface TopicFilterProps {
  topics: Topic[]
  topicFilter: string
  showArchived: boolean
}

export function TopicFilter({ topics, topicFilter, showArchived }: TopicFilterProps) {
  const router = useRouter()
  const searchParams = useSearchParams()

  function handleChange(e: React.ChangeEvent<HTMLSelectElement>) {
    const value = e.target.value
    const params = new URLSearchParams(searchParams.toString())
    
    if (value) params.set('topic', value)
    else params.delete('topic')
    
    // Sayfayı 1'e çekmeye gerek yok ama genelde iyi olur, burada pagination yok henüz
    router.push(`/dashboard/lessons?${params.toString()}`)
  }

  return (
    <div className="relative flex-1 min-w-[200px]">
      <select
        value={topicFilter}
        onChange={handleChange}
        className={`
          w-full appearance-none pl-4 pr-8 py-2.5 rounded-xl text-sm font-bold border transition-all
          bg-surface focus:outline-none focus:ring-2 focus:ring-brand-primary/20 cursor-pointer
          ${topicFilter
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
      <span className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-[10px] text-ink-disabled">▼</span>
    </div>
  )
}
