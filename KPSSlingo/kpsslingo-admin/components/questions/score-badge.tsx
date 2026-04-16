// components/questions/score-badge.tsx
'use client'

import { scoreToColor, scoreToLabel } from '@/lib/utils/score-calculator'

interface ScoreBadgeProps {
  score: number | null
}

export function ScoreBadge({ score }: ScoreBadgeProps) {
  if (score === null) return null

  const colorClasses = scoreToColor(score)
  const label = scoreToLabel(score)

  return (
    <div className={`
      inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full border border-current/10 font-bold tracking-tight
      ${colorClasses}
    `}>
      <span className="text-[10px] uppercase opacity-70">Kalite:</span>
      <span className="text-xs">{score.toFixed(1)}</span>
      <span className="text-[10px] px-1.5 py-0.5 rounded-md bg-white/20 dark:bg-black/20 uppercase">
        {label}
      </span>
    </div>
  )
}
