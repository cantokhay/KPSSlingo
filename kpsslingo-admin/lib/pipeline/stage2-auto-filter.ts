import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
const supabase = createClient(supabaseUrl, supabaseServiceKey)

interface FilterResult {
  passed: boolean
  failedRules: string[]
}

function applyRules(question: {
  body: string
  explanation: string | null
  correct_option: string
  question_options: { label: string; body: string }[]
}): FilterResult {
  const failedRules: string[] = []
  const options = question.question_options

  // Kural 1: Soru uzunluğu
  if (question.body.trim().length < 20)
    failedRules.push('Soru metni çok kısa (< 20 karakter)')
  if (question.body.trim().length > 600) // Adjusted from 400 to allow more detail
    failedRules.push('Soru metni çok uzun (> 600 karakter)')

  // Kural 2: 5 şık zorunlu
  if (options.length !== 5)
    failedRules.push(`Şık sayısı yanlış (${options.length}/5)`)

  // Kural 3: Şık etiketleri A-E
  const labels = options.map(o => o.label).sort()
  if (JSON.stringify(labels) !== JSON.stringify(['A','B','C','D','E']))
    failedRules.push('Şık etiketleri A-E dışında')

  // Kural 4: correct_option geçerli
  if (!['A','B','C','D','E'].includes(question.correct_option))
    failedRules.push('Doğru cevap geçersiz')

  // Kural 5: Explanation uzunluğu
  if (!question.explanation || question.explanation.trim().length < 20)
    failedRules.push('Açıklama eksik veya çok kısa')

  // Kural 6: Türkçe karakter yoğunluğu
  const turkishChars = /[çÇğĞıİöÖşŞüÜ]/g
  const turkishCount = (question.body.match(turkishChars) ?? []).length
  const totalLetters = (question.body.match(/[a-zA-ZçÇğĞıİöÖşŞüÜ]/g) ?? []).length
  if (totalLetters > 0 && turkishCount / totalLetters < 0.02 && question.body.length > 50)
    failedRules.push('Türkçe karakter yoğunluğu düşük (İngilizce metin şüphesi)')

  // Kural 7: Duplicate şık yok
  const optionBodies = options.map(o => o.body.trim().toLowerCase())
  const uniqueBodies = new Set(optionBodies)
  if (uniqueBodies.size !== optionBodies.length)
    failedRules.push('Birbirinin aynısı şıklar var')

  // Kural 8: Cevap sızıntısı kontrolü
  const correctOptionBody = options.find(o => o.label === question.correct_option)?.body ?? ''
  const correctWords = correctOptionBody.toLowerCase().split(/\s+/).filter(w => w.length > 4)
  const questionLower = question.body.toLowerCase()
  const leakCount = correctWords.filter(w => questionLower.includes(w)).length
  if (correctWords.length > 2 && leakCount / correctWords.length > 0.7)
    failedRules.push('Soru metni doğru cevabı ima ediyor (cevap sızıntısı)')

  return { passed: failedRules.length === 0, failedRules }
}

export async function runAutoFilter(jobId: string): Promise<{
  passed: number
  rejected: number
}> {
  // Bu job'a ait generating soruları çek
  const { data: questions, error } = await supabase
    .from('questions')
    .select('*, question_options(*)')
    .eq('generation_job_id', jobId)
    .eq('status', 'generating')

  if (error || !questions) return { passed: 0, rejected: 0 }

  let passedTotal = 0, rejectedTotal = 0

  for (const q of questions) {
    const result = applyRules({
      body: q.body,
      explanation: q.explanation,
      correct_option: q.correct_option,
      question_options: q.question_options ?? [],
    })

    if (result.passed) {
      await supabase
        .from('questions')
        .update({ status: 'pending_ai_review', auto_filter_passed: true })
        .eq('id', q.id)
      passedTotal++
    } else {
      await supabase
        .from('questions')
        .update({
          status: 'auto_rejected',
          auto_filter_passed: false,
          rejection_reason: result.failedRules.join(' | '),
          rejected_stage: 'auto_filter',
        })
        .eq('id', q.id)
      rejectedTotal++
    }
  }

  return { passed: passedTotal, rejected: rejectedTotal }
}
