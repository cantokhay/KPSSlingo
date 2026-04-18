// app/dashboard/questions/page.tsx
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { QuestionFilters } from '@/components/questions/question-filters'
import { GenerateQuestionsButton } from '@/components/questions/generate-questions-modal'
import { BulkApproveBar } from '@/components/questions/bulk-approve-bar'
import { SortableHeader } from '@/components/ui/sortable-header'

const PAGE_SIZE = 15

export default async function QuestionsPage({
  searchParams,
}: {
  searchParams: Promise<{ 
    status?: string; topic?: string; lesson?: string; page?: string; minScore?: string; suitability?: string;
    orderBy?: string; orderDir?: string;
  }>
}) {
  const params    = await searchParams
  const status    = params.status   ?? 'all'
  const topicId   = params.topic    ?? ''
  const lessonId  = params.lesson   ?? ''
  const minScore  = params.minScore ?? ''
  const suitability= params.suitability ?? ''
  const orderBy   = params.orderBy  ?? 'created_at'
  const orderDir  = (params.orderDir ?? 'desc') as 'asc' | 'desc'
  const page      = parseInt(params.page ?? '1')
  const from      = (page - 1) * PAGE_SIZE
  const to        = from + PAGE_SIZE - 1

  const supabase = await createSupabaseServerClient()

  // ── Filtre verilerini çek ─────────────────────────────────────────────────
  const [{ data: topics }, { data: lessons }] = await Promise.all([
    supabase.from('topics').select('id, title').eq('status', 'active').order('order'),
    supabase.from('lessons').select('id, title, topic_id').order('order'),
  ])

  // ── Sorular sorgusu ───────────────────────────────────────────────────────
  let query = supabase
    .from('questions')
    .select(`
      id, body, status, source, created_at, lesson_id, ai_review_score, difficulty_score, explanation,
      lessons ( id, title, topic_id, topics ( title ) ),
      question_options ( id, label, body )
    `, { count: 'exact' })
    .order(orderBy, { ascending: orderDir === 'asc' })
    .range(from, to)

  // Status filtresi
  if (status !== 'all') {
    if (status === 'draft') {
      // Bekleyenler kısmına AI onayı bekleyenleri ve draftleri dahil ediyoruz
      query = query.in('status', ['draft', 'draft_flagged', 'pending_ai_review'])
    } else if (status === 'rejected') {
      // Reddedilenler sayfası
      query = query.eq('status', 'ai_rejected')
    } else {
      query = query.eq('status', status)
    }
  }

  // Skor filtresi
  if (minScore) {
    query = query.gte('ai_review_score', parseFloat(minScore))
  }

  // Uygunluk (Zorluk) filtresi
  if (suitability) {
    if (suitability === 'ortaogretim') {
      query = query.lte('difficulty_score', 3.5)
    } else if (suitability === 'onlisans') {
      query = query.gte('difficulty_score', 3.6).lte('difficulty_score', 7.0)
    } else if (suitability === 'lisans') {
      query = query.gte('difficulty_score', 7.1)
    }
  }

  // Ders filtresi
  if (lessonId) {
    query = query.eq('lesson_id', lessonId)
  }
  // Konu filtresi (ders seçilmediyse)
  else if (topicId) {
    const topicLessonIds = (lessons ?? [])
      .filter((l) => l.topic_id === topicId)
      .map((l) => l.id)

    if (topicLessonIds.length > 0) {
      query = query.in('lesson_id', topicLessonIds)
    }
  }

  const { data: questions, count } = await query
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE)

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      {/* Page Header */}
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold text-ink-primary dark:text-gray-100 tracking-tight">Soru Yönetimi</h1>
          <p className="text-ink-secondary dark:text-gray-400 font-medium mt-1">
            İçerikleri gözden geçirin, düzenleyin ve yayınlayın.
            {count != null && (
              <span className="ml-2 text-[11px] font-bold text-ink-disabled dark:text-gray-600 uppercase tracking-wider">
                ({count} sonuç)
              </span>
            )}
          </p>
        </div>
        <GenerateQuestionsButton />
      </header>

      {/* Filters Bar */}
      <section className="bg-surface rounded-[24px] border border-ink-disabled/10 p-2 shadow-sm">
        <QuestionFilters
          currentStatus={status}
          topics={topics ?? []}
          lessons={lessons ?? []}
        />
      </section>
      
      {/* Search Result & Sorting Information */}
      <div className="flex items-center justify-between px-2">
         <div className="flex items-center gap-6">
            <SortableHeader 
              label="Tarih" 
              sortKey="created_at" 
              currentOrderBy={orderBy} 
              currentOrderDir={orderDir} 
            />
            <SortableHeader 
              label="Kalite" 
              sortKey="ai_review_score" 
              currentOrderBy={orderBy} 
              currentOrderDir={orderDir} 
            />
         </div>
         <span className="text-[10px] font-bold text-ink-secondary opacity-50 uppercase tracking-widest">
           Sıralama: {orderBy === 'created_at' ? 'Tarih' : 'Kalite'} ({orderDir === 'asc' ? 'Artan' : 'Azalan'})
         </span>
      </div>

      {/* Sorular listesi + Toplu onay */}
      <BulkApproveBar questions={(questions as any[]) ?? []} />

      {/* Pagination Bar */}
      {totalPages > 1 && (
        <nav className="flex items-center justify-center gap-2 pt-4">
          {Array.from({ length: totalPages }, (_, i) => i + 1).map((p) => (
            <a
              key={p}
              href={`/dashboard/questions?status=${status}&page=${p}${topicId ? `&topic=${topicId}` : ''}${lessonId ? `&lesson=${lessonId}` : ''}${minScore ? `&minScore=${minScore}` : ''}${suitability ? `&suitability=${suitability}` : ''}`}
              className={`
                w-10 h-10 flex items-center justify-center rounded-xl text-sm font-bold
                transition-all duration-200 border
                ${p === page
                  ? 'bg-brand-primary text-white border-brand-primary shadow-lg shadow-brand-primary/20 scale-110'
                  : 'bg-surface border-ink-disabled/10 text-ink-secondary hover:border-brand-primary/40'
                }
              `}
            >
              {p}
            </a>
          ))}
        </nav>
      )}
    </div>
  )
}
