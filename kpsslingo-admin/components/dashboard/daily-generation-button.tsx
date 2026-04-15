'use client'

import { useState, useTransition } from 'react'
import { runDailyPipelineAction } from '@/lib/actions/generation-actions'

export function DailyGenerationButton() {
  const [isPending, startTransition] = useTransition()
  const [result, setResult] = useState<{ lessonsProcessed: number, questionsAdded: number } | null>(null)
  const [progress, setProgress] = useState(0)
  const [minThreshold, setMinThreshold] = useState(30)
  const [targetCount, setTargetCount] = useState(60)

  function handleTrigger() {
    setResult(null)
    setProgress(0)

    // Simulate progress while the server action runs
    const interval = setInterval(() => {
      setProgress(prev => {
        if (prev >= 90) return prev
        return prev + (100 - prev) * 0.1
      })
    }, 1500)

    startTransition(async () => {
      try {
        const res = await runDailyPipelineAction({ minThreshold, targetCount })
        clearInterval(interval)
        setProgress(100)
        setResult(res as any)
      } catch (error: any) {
        clearInterval(interval)
        alert("Üretim sırasında hata: " + error.message)
      }
    })
  }

  return (
    <section className="bg-surface rounded-[32px] border border-ink-disabled/10 p-8 shadow-sm">
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-8 mb-8">
        <div>
          <h2 className="text-xl font-bold text-ink-primary flex items-center gap-2">
            <span className="text-2xl">🔄</span> Günlük Üretim Paneli
          </h2>
          <p className="text-ink-secondary text-sm mt-1 max-w-md">
            Eksik içerikli dersleri tespit eder ve otomatik olarak soru üretir. Eşik değerlerini aşağıdan özelleştirebilirsiniz.
          </p>
        </div>

        {!isPending && !result && (
          <div className="flex flex-wrap items-center gap-4 bg-surface-alt/50 p-4 rounded-3xl border border-ink-disabled/5">
            <div className="flex flex-col gap-1">
              <label className="text-[10px] uppercase tracking-widest text-ink-disabled font-bold ml-3">Min. Eşik</label>
              <input 
                type="number" 
                value={minThreshold}
                onChange={(e) => setMinThreshold(Number(e.target.value))}
                className="w-20 bg-surface border border-ink-disabled/10 rounded-2xl py-2 px-3 text-sm font-bold text-ink-primary focus:outline-none focus:ring-2 focus:ring-brand-primary/20"
              />
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-[10px] uppercase tracking-widest text-ink-disabled font-bold ml-3">Hedef Soru</label>
              <input 
                type="number" 
                value={targetCount}
                onChange={(e) => setTargetCount(Number(e.target.value))}
                className="w-20 bg-surface border border-ink-disabled/10 rounded-2xl py-2 px-3 text-sm font-bold text-ink-primary focus:outline-none focus:ring-2 focus:ring-brand-primary/20"
              />
            </div>
            <button
              onClick={handleTrigger}
              className="bg-brand-primary text-white font-bold py-3 px-8 rounded-2xl
                         hover:bg-brand-light transition-all shadow-lg shadow-brand-primary/20
                         active:scale-95 ml-2"
            >
              Üretimi Başlat
            </button>
          </div>
        )}
      </div>

      {isPending && (
        <div className="space-y-4 animate-in fade-in">
          <div className="flex items-center justify-between text-xs font-bold uppercase tracking-widest text-ink-secondary">
            <span>Üretim Devam Ediyor...</span>
            <span>%{Math.round(progress)}</span>
          </div>
          <div className="h-3 bg-surface-alt rounded-full overflow-hidden border border-ink-disabled/5">
            <div 
              className="h-full bg-brand-primary transition-all duration-500 ease-out"
              style={{ width: `${progress}%` }}
            />
          </div>
          <p className="text-[11px] text-ink-disabled font-medium italic">
            Ders içerikleri analiz ediliyor ve AI modelleri çalıştırılıyor. Bu işlem 1 dakikaya kadar sürebilir.
          </p>
        </div>
      )}

      {result && (
        <div className="bg-semantic-success/5 border border-semantic-success/20 rounded-2xl p-6 animate-in slide-in-from-top-2">
          <div className="flex items-center gap-3 text-semantic-success font-bold mb-2">
            <span className="text-xl">✅</span>
            <span>İşlem Başarıyla Tamamlandı</span>
          </div>
          <div className="grid grid-cols-2 gap-4 mt-4">
            <div className="bg-surface-alt p-3 rounded-xl border border-semantic-success/10 text-center">
              <p className="text-[10px] uppercase tracking-widest text-ink-disabled font-bold">İşlenen Ders</p>
              <p className="text-2xl font-black text-ink-primary">{result.lessonsProcessed}</p>
            </div>
            <div className="bg-surface-alt p-3 rounded-xl border border-semantic-success/10 text-center">
              <p className="text-[10px] uppercase tracking-widest text-ink-disabled font-bold">Eklenen Soru</p>
              <p className="text-2xl font-black text-ink-primary">{result.questionsAdded}</p>
            </div>
          </div>
          <button 
            onClick={() => setResult(null)}
            className="w-full mt-6 py-2 text-xs font-bold text-ink-secondary hover:text-ink-primary transition-colors"
          >
            Paneli Temizle
          </button>
        </div>
      )}
    </section>
  )
}
