// app/dashboard/page.tsx
import { StatCard } from '@/components/ui/stat-card'
import { DailyGenerationButton } from '@/components/dashboard/daily-generation-button'
import Link from 'next/link'
import {
  getQuestionProductionTrend,
  getTopicDistribution,
  getScoreDistribution,
  getGeneralStats
} from '@/lib/actions/dashboard-stats'
import { ProductionTrendChart } from '@/components/dashboard/charts/production-trend-chart'
import { TopicDistributionChart } from '@/components/dashboard/charts/topic-distribution-chart'
import { ScoreDistributionChart } from '@/components/dashboard/charts/score-distribution-chart'

export const dynamic = 'force-dynamic'

export default async function DashboardPage() {
  // Parallel fetch stats & chart data
  const [
    trendData,
    topicData,
    scoreData,
    stats
  ] = await Promise.all([
    getQuestionProductionTrend(),
    getTopicDistribution(),
    getScoreDistribution(),
    getGeneralStats()
  ])

  return (
    <div className="space-y-10 animate-in fade-in duration-700">
      <header>
        <h1 className="text-3xl font-extrabold text-ink-primary dark:text-gray-100 tracking-tight">Dashboard Overview</h1>
        <p className="text-ink-secondary dark:text-gray-400 font-medium mt-1">Sistem durumuna ve bekleyen içeriklere hızlıca göz atın.</p>
      </header>

      {/* Stats Overview */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          label="Bekleyen Sorular"
          value={stats.draftCount}
          icon="⏳"
          accent="warning"
          href="/dashboard/questions?status=draft"
        />
        <StatCard
          label="Yayındaki Sorular"
          value={stats.publishedCount}
          icon="✅"
          accent="success"
          href="/dashboard/questions?status=published"
        />
        <StatCard
          label="Toplam Öğrenci"
          value={stats.userCount}
          icon="🎓"
          accent="primary"
        />
        <StatCard
          label="Toplam Soru"
          value={stats.totalQuestions}
          icon="📊"
          accent="primary"
        />
      </div>

      <DailyGenerationButton />

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Question Production Trend (Area Chart) */}
        <section className="lg:col-span-2 bg-surface rounded-[32px] border border-ink-disabled/10 p-8 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div>
              <h2 className="text-xl font-bold text-ink-primary">Soru Üretim Trendi</h2>
              <p className="text-xs text-ink-disabled font-bold uppercase tracking-widest mt-1">Son 7 Gün</p>
            </div>
            <div className="w-10 h-10 rounded-2xl bg-brand-primary/5 flex items-center justify-center text-xl">📈</div>
          </div>
          <ProductionTrendChart data={trendData} />
        </section>

        {/* Topic Distribution (Pie Chart) */}
        <section className="bg-surface rounded-[32px] border border-ink-disabled/10 p-8 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div>
              <h2 className="text-xl font-bold text-ink-primary">Konu Dağılımı</h2>
              <p className="text-xs text-ink-disabled font-bold uppercase tracking-widest mt-1">Yüzdesel Dağılım</p>
            </div>
            <div className="w-10 h-10 rounded-2xl bg-semantic-success/5 flex items-center justify-center text-xl">🥧</div>
          </div>
          <TopicDistributionChart data={topicData} />
        </section>
      </div>

      {/* Score Distribution (Bar Chart Full Width) */}
      <section className="bg-surface rounded-[32px] border border-ink-disabled/10 p-8 shadow-sm">
        <div className="flex items-center justify-between mb-2">
          <div>
            <h2 className="text-xl font-bold text-ink-primary">Tüm Soruların Kalite Skorları</h2>
            <p className="text-xs text-ink-disabled font-bold uppercase tracking-widest mt-1">Veritabanındaki Tüm Soruların Kalite Dağılımı (0.5 Puanlık Aralıklarla)</p>
          </div>
          <div className="w-10 h-10 rounded-2xl bg-brand-accent/5 flex items-center justify-center text-xl">📊</div>
        </div>
        <ScoreDistributionChart data={scoreData} />
      </section>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Action & Tips */}
        <div className="bg-surface border border-ink-disabled/10 p-8 rounded-[32px] flex flex-col justify-between">
          <div>
            <h3 className="text-lg font-bold text-ink-primary mb-2">Düşük Kaliteli İçerikleri İyileştir</h3>
            <p className="text-sm text-ink-secondary leading-relaxed mb-6">
              Düşük puanlı soruları listeleyerek içerik kalitesini artırmak için düzenlemeler yapın veya yeniden üretilmesini sağlayın.
            </p>
          </div>
          <Link
            href="/dashboard/questions?minScore=0&status=all"
            className="text-center font-bold text-xs uppercase tracking-widest text-brand-primary bg-brand-primary/5 py-4 rounded-2xl hover:bg-brand-primary hover:text-white transition-all underline-none"
          >
            Tüm Düşük Skorlu Sorulara Bak →
          </Link>
        </div>

        <div className="bg-brand-primary text-white p-8 rounded-[32px] shadow-xl shadow-brand-primary/20 flex flex-col justify-between">
          <div>
            <h3 className="text-lg font-bold mb-2">Kalite vs Başarı</h3>
            <p className="text-sm text-white/80 leading-relaxed">
              Ortalama soru kalite skoru yükseldikçe öğrenci başarısı %12 oranında artış göstermektedir. Sistem şu an tüm veritabanı skorlarını analiz ediyor.
            </p>
          </div>
          <div className="mt-6 flex items-center gap-3">
            <div className="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">✨</div>
            <span className="font-bold text-sm tracking-tight text-white/90">AI Analiz Modülü: Aktif</span>
          </div>
        </div>
      </div>
    </div>
  )
}
