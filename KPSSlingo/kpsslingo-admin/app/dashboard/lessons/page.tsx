// app/dashboard/lessons/page.tsx
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { LessonFormModal } from '@/components/lessons/lesson-form-modal'
import { SoftDeleteButton } from '@/components/lessons/soft-delete-button'
import { SortableHeader } from '@/components/ui/sortable-header'
import { TopicFilter } from '@/components/lessons/topic-filter'

const DIFFICULTY_META = {
  beginner:     { label: 'Başlangıç', cls: 'text-semantic-success bg-semantic-success/10'  },
  intermediate: { label: 'Orta',      cls: 'text-semantic-warning bg-semantic-warning/10'  },
  advanced:     { label: 'İleri',     cls: 'text-semantic-error   bg-semantic-error/10'    },
}

const STATUS_META = {
  draft:     { label: 'Taslak',       dot: 'bg-ink-disabled'       },
  published: { label: 'Yayında',      dot: 'bg-semantic-success'   },
  archived:  { label: 'Arşivlendi',   dot: 'bg-semantic-error'     },
}

export default async function LessonsPage({
  searchParams,
}: {
  searchParams: Promise<{ 
    topic?: string; 
    showArchived?: string;
    orderBy?: string;
    orderDir?: string;
  }>
}) {
  const params       = await searchParams
  const topicFilter  = params.topic        ?? ''
  const showArchived = params.showArchived === '1'
  const orderBy      = params.orderBy      ?? 'order'
  const orderDir     = (params.orderDir    ?? 'asc') as 'asc' | 'desc'

  const supabase = await createSupabaseServerClient()

  const [{ data: topics }, { data: lessons }] = await Promise.all([
    supabase.from('topics').select('id, title').eq('status', 'active').order('order'),
    (async () => {
      let q = supabase
        .from('lessons')
        .select('*, topics(id, title)')
        .order(orderBy, { ascending: orderDir === 'asc' })

      if (topicFilter) q = q.eq('topic_id', topicFilter)
      if (!showArchived) q = q.neq('status', 'archived')

      return q
    })(),
  ])

  return (
    <div className="space-y-8 animate-in fade-in duration-500">

      {/* Page Header */}
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold text-ink-primary tracking-tight">Ders Yönetimi</h1>
          <p className="text-ink-secondary font-medium mt-1">
            Ders içeriklerini ve zorluk seviyelerini yönetin.
          </p>
        </div>

        {/* Yeni Ders butonu */}
        <LessonFormModal
          topics={topics ?? []}
          defaultTopicId={topicFilter}
          trigger={
            <button className="
              flex items-center gap-2 px-5 py-3 rounded-card text-sm font-bold
              bg-brand-primary text-white shadow-lg shadow-brand-primary/25
              hover:bg-brand-light hover:-translate-y-0.5 active:translate-y-0
              transition-all duration-200
            ">
              <span className="text-lg">➕</span>
              <span>Yeni Ders Ekle</span>
            </button>
          }
        />
      </header>

      {/* Filtre Barı */}
      <div className="flex flex-wrap items-center gap-3 bg-surface rounded-[24px] border border-ink-disabled/10 px-4 py-3 shadow-sm">
        {/* Konu dropdown (Client Component) */}
        <TopicFilter topics={topics ?? []} topicFilter={topicFilter} showArchived={showArchived} />

        {/* Arşiv toggle */}
        <a
          href={`/dashboard/lessons?${topicFilter ? `topic=${topicFilter}&` : ''}showArchived=${showArchived ? '0' : '1'}`}
          className={`
            flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-bold border transition-all duration-200 whitespace-nowrap
            ${showArchived
              ? 'bg-semantic-error/10 text-semantic-error border-semantic-error/20 hover:bg-semantic-error hover:text-white hover:border-semantic-error'
              : 'bg-surface-alt text-ink-secondary border-ink-disabled/10 hover:border-brand-primary/40'
            }
          `}
        >
          {showArchived ? '⊘ Arşivlenenleri Gizle' : '⊘ Arşivlenenleri Göster'}
        </a>

        {topicFilter && (
          <a
            href="/dashboard/lessons"
            className="flex items-center gap-1.5 px-3 py-2.5 rounded-xl text-xs font-bold
                       text-semantic-error bg-semantic-error/10 border border-semantic-error/20
                       hover:bg-semantic-error hover:text-white transition-all duration-200"
          >
            <span>✕</span>
            <span>Filtreyi Temizle</span>
          </a>
        )}
      </div>

      {/* Ders tablosu */}
      <div className="bg-surface rounded-[32px] border border-ink-disabled/10 overflow-hidden shadow-sm">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-surface-alt border-b border-ink-disabled/5">
              <th className="px-6 py-4">
                <SortableHeader label="Ders Başlığı" sortKey="title" currentOrderBy={orderBy} currentOrderDir={orderDir} />
              </th>
              <th className="px-6 py-4 text-[10px] font-bold text-ink-secondary uppercase tracking-widest">Konu</th>
              <th className="px-6 py-4 text-[10px] font-bold text-ink-secondary uppercase tracking-widest">Zorluk</th>
              <th className="px-6 py-4 min-w-[90px] whitespace-nowrap">
                <SortableHeader label="XP" sortKey="xp_reward" currentOrderBy={orderBy} currentOrderDir={orderDir} />
              </th>
              <th className="px-6 py-4 text-[10px] font-bold text-ink-secondary uppercase tracking-widest">Durum</th>
              <th className="px-6 py-4 text-[10px] font-bold text-ink-secondary uppercase tracking-widest text-right">İşlemler</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-ink-disabled/5">
            {(lessons ?? []).length === 0 ? (
              <tr>
                <td colSpan={6} className="px-6 py-16 text-center">
                  <div className="text-3xl mb-3">📚</div>
                  <p className="text-ink-secondary font-bold">Ders bulunamadı.</p>
                  <p className="text-ink-disabled text-sm mt-1">Filtreleri değiştirmeyi veya yeni ders eklemeyi deneyin.</p>
                </td>
              </tr>
            ) : (
              (lessons ?? []).map((lesson) => {
                const diff   = DIFFICULTY_META[lesson.difficulty as keyof typeof DIFFICULTY_META]
                const status = STATUS_META[lesson.status as keyof typeof STATUS_META]
                const isArch = lesson.status === 'archived'

                return (
                  <tr
                    key={lesson.id}
                    className={`group transition-colors ${isArch ? 'opacity-50 hover:opacity-70 bg-surface-alt/40' : 'hover:bg-surface-alt'}`}
                  >
                    {/* Başlık */}
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <span className="text-[11px] font-mono text-ink-disabled bg-surface-muted px-1.5 py-0.5 rounded">
                          #{lesson.order}
                        </span>
                        <span className="text-sm font-bold text-ink-primary">{lesson.title}</span>
                      </div>
                      {lesson.description && (
                        <p className="text-[11px] text-ink-secondary mt-0.5 line-clamp-1 ml-8">{lesson.description}</p>
                      )}
                    </td>

                    {/* Konu */}
                    <td className="px-6 py-4">
                      <span className="text-[10px] font-bold bg-brand-primary/5 text-brand-primary px-2 py-1 rounded-full uppercase tracking-wide">
                        {(lesson.topics as any)?.title}
                      </span>
                    </td>

                    {/* Zorluk */}
                    <td className="px-6 py-4">
                      <span className={`text-[10px] font-bold uppercase tracking-widest px-2 py-1 rounded-full ${diff?.cls}`}>
                        {diff?.label}
                      </span>
                    </td>

                    {/* XP */}
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="text-xs font-bold text-[#D97706]">⭐ {lesson.xp_reward} XP</span>
                    </td>

                    {/* Durum */}
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <span className={`w-2 h-2 rounded-full ${status?.dot}`} />
                        <span className="text-xs font-semibold text-ink-secondary">{status?.label}</span>
                      </div>
                    </td>

                    {/* İşlemler */}
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-end gap-2">
                        {/* Düzenle */}
                        <LessonFormModal
                          topics={topics ?? []}
                          lesson={{
                            id:          lesson.id,
                            title:       lesson.title,
                            topic_id:    lesson.topic_id,
                            difficulty:  lesson.difficulty as 'beginner' | 'intermediate' | 'advanced',
                            order:       lesson.order,
                            description: lesson.description,
                            xp_reward:   lesson.xp_reward,
                            status:      lesson.status as 'draft' | 'published' | 'archived',
                          }}
                          trigger={
                            <button className="
                              inline-flex items-center gap-1 px-3 py-1.5 rounded-xl
                              text-[10px] font-bold border border-brand-primary/30
                              text-brand-primary bg-brand-primary/5
                              hover:bg-brand-primary hover:text-white hover:border-brand-primary
                              transition-all duration-200
                            ">
                              <span>✏️</span>
                              <span>Düzenle</span>
                            </button>
                          }
                        />

                        {/* Pasife Al / Geri Al */}
                        <SoftDeleteButton
                          lessonId={lesson.id}
                          lessonTitle={lesson.title}
                          isArchived={isArch}
                        />
                      </div>
                    </td>
                  </tr>
                )
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Sonuç özeti */}
      <p className="text-[11px] font-bold text-ink-disabled text-center uppercase tracking-widest">
        {lessons?.length ?? 0} ders listeleniyor
        {topicFilter ? ` — filtreli` : ''}
      </p>
    </div>
  )
}
