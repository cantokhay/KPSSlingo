// app/dashboard/questions/[id]/page.tsx
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import { QuestionEditForm } from '@/components/questions/question-edit-form'
import Link from 'next/link'
import { ScoreBadge } from '@/components/questions/score-badge'

export default async function QuestionDetailPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const supabase = await createSupabaseServerClient()

  const { data: question } = await supabase
    .from('questions')
    .select(`
      *,
      question_options(*),
      lessons ( title, topics ( title ) )
    `)
    .eq('id', id)
    .single()

  if (!question) {
      notFound()
  }

  return (
    <div className="max-w-4xl mx-auto animate-in fade-in slide-in-from-bottom-4 duration-500">
      {/* Navigation Breadcrumb */}
      <nav className="flex items-center gap-3 mb-8 text-sm font-bold">
        <Link
          href="/dashboard/questions"
          className="text-ink-secondary hover:text-brand-primary transition-colors flex items-center gap-1"
        >
          <span>←</span>
          <span>Soru Listesi</span>
        </Link>
        <span className="text-ink-disabled">/</span>
        <div className="flex items-center gap-1.5 text-ink-secondary">
          <span className="opacity-50">{(question.lessons as any)?.topics?.title}</span>
          <span className="text-ink-disabled opacity-30">›</span>
          <span className="opacity-50">{(question.lessons as any)?.title}</span>
        </div>
      </nav>

      {/* Header Info */}
      <header className="flex items-center justify-between mb-10 border-b border-slate-200 pb-8">
        <div>
          <h1 className="text-3xl font-extrabold text-ink-primary tracking-tight">Soru İnceleme</h1>
          <p className="text-ink-secondary font-medium mt-1 flex items-center gap-2">
            ID: <code className="bg-surface-muted px-2 py-0.5 rounded text-[11px] font-mono">{question.id}</code>
          </p>
          <div className="mt-4 flex items-center gap-3">
             <ScoreBadge score={question.ai_review_score} />
          </div>
        </div>

        <div className={`
          px-4 py-2 rounded-full text-xs font-black uppercase tracking-widest
          ${question.status === 'draft'
            ? 'bg-semantic-warning/15 text-semantic-warning'
            : question.status === 'draft_flagged'
              ? 'bg-[#FEF3C7] text-[#D97706] border border-[#FCD34D]'
              : question.status === 'published'
                ? 'bg-semantic-success/15 text-semantic-success'
                : 'bg-ink-disabled/20 text-ink-secondary'
          }
        `}>
          {question.status}
        </div>
      </header>

      {/* AI Review Alerts */}
      {question.ai_review_issues && question.ai_review_issues.length > 0 && (
        <div className="bg-semantic-warning/5 border border-semantic-warning/20 rounded-[20px] p-6 mb-8 group transition-all duration-300 hover:border-semantic-warning/40 hover:shadow-lg hover:shadow-semantic-warning/5">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 rounded-xl bg-semantic-warning/10 flex items-center justify-center text-xl">
              ⚠
            </div>
            <div>
              <p className="text-sm font-black text-semantic-warning uppercase tracking-widest">
                AI İnceleme Uyarıları
              </p>
              <p className="text-xs font-bold text-ink-secondary opacity-60">
                Kalite Skoru: {question.ai_review_score?.toFixed(1) ?? '0.0'} / 10
              </p>
            </div>
          </div>
          <ul className="grid gap-3">
            {question.ai_review_issues.map((issue: string, i: number) => (
              <li key={i} className="text-[13px] font-semibold text-ink-secondary flex items-start gap-3 pl-1">
                <span className="w-1.5 h-1.5 rounded-full bg-semantic-warning mt-1.5 shrink-0" />
                {issue}
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* Main Edit Form */}
      <QuestionEditForm question={question as any} />

      {/* Audit Log / Meta Info */}
      <footer className="mt-16 pt-8 border-t border-slate-100 grid grid-cols-2 gap-8 text-[11px] font-bold text-ink-disabled uppercase tracking-widest">
        <div>
            <p className="mb-1">Oluşturulma</p>
            <p className="text-ink-secondary">{new Date(question.created_at).toLocaleString('tr-TR')}</p>
        </div>
        {question.reviewed_at && (
            <div className="text-right">
                <p className="mb-1">Son İnceleme</p>
                <p className="text-ink-secondary">{new Date(question.reviewed_at).toLocaleString('tr-TR')}</p>
            </div>
        )}
      </footer>
    </div>
  )
}
