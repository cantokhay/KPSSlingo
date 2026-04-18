// components/questions/difficulty-badge.tsx
"use client";

export function getDifficultyColor(score: number): string {
  if (score <= 3.5) return "text-semantic-success bg-semantic-success/10"; // Yeşil
  if (score <= 7.0) return "text-brand-accent bg-brand-accent/10"; // Turuncu
  return "text-semantic-error bg-semantic-error/10"; // Kırmızı
}

export function getDifficultyLabel(score: number): string {
  if (score <= 3.5) return "Ortaöğretim";
  if (score <= 7.0) return "Önlisans";
  return "Lisans";
}

interface DifficultyBadgeProps {
  score: number | null;
}

export function DifficultyBadge({ score }: DifficultyBadgeProps) {
  if (score === null || score === undefined) return null;

  const colorClasses = getDifficultyColor(score);
  const label = getDifficultyLabel(score);

  return (
    <div
      className={`
      inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full border border-current/10 font-bold tracking-tight
      ${colorClasses}
    `}
    >
      <span className="text-[10px] uppercase opacity-70">Zorluk:</span>
      <span className="text-xs">{score.toFixed(1)}</span>
      <span className="text-[10px] px-1.5 py-0.5 rounded-md bg-white/20 dark:bg-black/20 uppercase">
        {label}
      </span>
    </div>
  );
}
