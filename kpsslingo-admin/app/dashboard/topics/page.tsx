// app/dashboard/topics/page.tsx
import { createSupabaseServerClient } from '@/lib/supabase/server'
import Link from 'next/link'

import { SortableHeader } from '@/components/ui/sortable-header'

export default async function TopicsPage({
  searchParams,
}: {
  searchParams: Promise<{ orderBy?: string; orderDir?: string }>
}) {
  const params    = await searchParams
  const orderBy   = params.orderBy  ?? 'order'
  const orderDir  = (params.orderDir ?? 'asc') as 'asc' | 'desc'
  const supabase = await createSupabaseServerClient()
  
  const { data: topics } = await supabase
    .from('topics')
    .select('*')
    .order(orderBy, { ascending: orderDir === 'asc' })

  // Her konudaki ders sayısını da çekelim
  const { data: lessonCounts } = await supabase
    .from('lessons')
    .select('topic_id')
    .neq('status', 'archived')

  const countMap: Record<string, number> = {}
  lessonCounts?.forEach((l) => {
    countMap[l.topic_id] = (countMap[l.topic_id] ?? 0) + 1
  })

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <header>
        <h1 className="text-3xl font-extrabold text-ink-primary tracking-tight">Konu Yönetimi</h1>
        <p className="text-ink-secondary font-medium mt-1">
          Müfredat başlıklarını görüntüleyin. Bir konuya tıklayarak derslere geçin.
        </p>
      </header>

      {/* Sorting Bar */}
      <div className="flex items-center gap-6 px-2">
          <SortableHeader 
            label="Sıra" 
            sortKey="order" 
            currentOrderBy={orderBy} 
            currentOrderDir={orderDir} 
          />
          <SortableHeader 
            label="Başlık" 
            sortKey="title" 
            currentOrderBy={orderBy} 
            currentOrderDir={orderDir} 
          />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {topics?.map((topic) => {
          const lessonCount = countMap[topic.id] ?? 0

          return (
            <Link
              key={topic.id}
              href={`/dashboard/lessons?topic=${topic.id}`}
              className={`
                group block bg-surface border border-ink-disabled/10
                rounded-[24px] p-6 transition-all duration-300 cursor-pointer
                hover:border-brand-primary/40 hover:shadow-xl hover:shadow-brand-primary/10
                hover:-translate-y-1
                ${topic.status !== 'active' ? 'opacity-60' : ''}
              `}
            >
              {/* Üst kısım: ikon + durum */}
              <div className="flex items-center justify-between mb-4">
                <div className="w-12 h-12 rounded-2xl bg-brand-primary/10 flex items-center justify-center group-hover:bg-brand-primary/20 transition-all duration-300">
                  <span className="text-2xl">🗂️</span>
                </div>
                <span className={`
                  text-[10px] font-bold px-2.5 py-1 rounded-full uppercase tracking-widest
                  ${topic.status === 'active'
                    ? 'bg-semantic-success/10 text-semantic-success'
                    : 'bg-ink-disabled/10 text-ink-secondary'
                  }
                `}>
                  {topic.status === 'active' ? 'Aktif' : 'Pasif'}
                </span>
              </div>

              {/* Başlık */}
              <h3 className="text-lg font-bold text-ink-primary group-hover:text-brand-primary transition-colors duration-200">
                {topic.title}
              </h3>

              {/* Açıklama */}
              <p className="text-sm text-ink-secondary mt-2 line-clamp-2 min-h-[40px]">
                {topic.description || 'Açıklama belirtilmemiş.'}
              </p>

              {/* Alt kısım: ders sayısı + ok */}
              <div className="mt-5 pt-5 border-t border-ink-disabled/5 flex items-center justify-between">
                <div className="flex items-center gap-4 text-[11px] font-bold text-ink-disabled uppercase tracking-widest">
                  <span>
                    📚 {lessonCount} ders
                  </span>
                  <span>·</span>
                  <span>Sıra: {topic.order}</span>
                </div>

                {/* "Derslere Git" göstergesi — hover'da belirir */}
                <div className="
                  flex items-center gap-1 text-[10px] font-bold text-brand-primary
                  opacity-0 group-hover:opacity-100 translate-x-2 group-hover:translate-x-0
                  transition-all duration-300
                ">
                  <span>Derslere Git</span>
                  <span>→</span>
                </div>
              </div>
            </Link>
          )
        })}
      </div>
    </div>
  )
}
