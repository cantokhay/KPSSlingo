// lib/utils/score-calculator.ts

interface ScoreInput {
  body:        string
  explanation: string | null
  status:      string
  source:      string
}

/**
 * Kural tabanlı soru kalite skoru hesaplayıcı (0-10 arası).
 * DB'deki calculate_question_score() fonksiyonu ile aynı mantık kullanılır.
 *
 * Puan dağılımı:
 *   5   — başlangıç puanı
 *  +1   — body > 150 karakter
 *  +2   — explanation mevcut ve > 80 karakter
 *  +1   — status != 'draft_flagged'
 *  +1   — source == 'ai_generated'
 * ──────────────────
 * max: 10
 */
export function calculateQuestionScore(input: ScoreInput): number {
  let score = 5

  if (input.body.length > 150)                                             score += 1
  if (input.explanation && input.explanation.length > 80)                  score += 2
  if (input.status !== 'draft_flagged')                                    score += 1
  if (input.source === 'ai_generated')                                     score += 1

  return Math.min(10, Math.max(0, score))
}

/** Skoru 0-10 → renge dönüştürür */
export function scoreToColor(score: number): string {
  if (score >= 8)  return 'text-semantic-success bg-semantic-success/10'
  if (score >= 6)  return 'text-semantic-warning bg-semantic-warning/10'
  return 'text-semantic-error bg-semantic-error/10'
}

/** Skoru 0-10 → insan dostu label'a dönüştür */
export function scoreToLabel(score: number): string {
  if (score >= 8)  return 'Yüksek'
  if (score >= 6)  return 'Orta'
  return 'Düşük'
}
