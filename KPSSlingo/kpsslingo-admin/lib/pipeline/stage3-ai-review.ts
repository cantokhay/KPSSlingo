import { GoogleGenerativeAI } from '@google/generative-ai'
import { callWithRetry } from './utils'
import { createClient } from '@supabase/supabase-js'
import { AI_REVIEW_SYSTEM } from './prompts'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!)

const supabase = createClient(supabaseUrl, supabaseServiceKey)

interface ReviewResult {
  valid: boolean
  confidence: number
  issues: string[]
}

function extractJSON(text: string) {
  let cleaned = text.trim()

  // Remove markdown code blocks if present
  if (cleaned.startsWith('```json')) {
    cleaned = cleaned.replace(/^```json/, '').replace(/```$/, '').trim()
  } else if (cleaned.startsWith('```')) {
    cleaned = cleaned.replace(/^```/, '').replace(/```$/, '').trim()
  }

  try {
    return JSON.parse(cleaned)
  } catch (initialError: any) {
    console.warn('AI Review JSON parse failed, attempting recovery...', initialError.message)

    // Find first { and last }
    const firstBrace = cleaned.indexOf('{')
    const lastBrace = cleaned.lastIndexOf('}')

    if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
      const jsonContent = cleaned.substring(firstBrace, lastBrace + 1)
      try {
        return JSON.parse(jsonContent)
      } catch (e: any) {
        // Ultimate fallback: Simple bracket closing
        let attempt = jsonContent
        const openBraces = (attempt.match(/\{/g) || []).length
        const closeBraces = (attempt.match(/\}/g) || []).length
        for (let i = 0; i < (openBraces - closeBraces); i++) attempt += '}'

        try {
          return JSON.parse(attempt)
        } catch {
          return null
        }
      }
    }
    return null
  }
}

async function reviewSingleQuestion(question: {
  body: string
  explanation: string | null
  correct_option: string
  question_options: { label: string; body: string }[]
}): Promise<ReviewResult> {
  const optionsText = question.question_options
    .sort((a, b) => a.label.localeCompare(b.label))
    .map(o => `${o.label}) ${o.body}`)
    .join('\n')

  const userContent = `SORU: ${question.body}

ŞIKLAR:
${optionsText}

DOĞRU CEVAP: ${question.correct_option}

AÇIKLAMA: ${question.explanation ?? '(yok)'}`

  try {
    const model = genAI.getGenerativeModel({
      model: 'gemini-flash-latest',
      systemInstruction: AI_REVIEW_SYSTEM,
      generationConfig: {
        responseMimeType: "application/json",
        maxOutputTokens: 1024,
        temperature: 0.2 // More deterministic for review
      }
    })

    const result = await callWithRetry(() => model.generateContent(userContent))
    const text = result.response.text()
    const parsed = extractJSON(text.trim())

    if (parsed) return parsed as ReviewResult
    throw new Error('Invalid JSON from AI Review')
  } catch (err) {
    console.error('AI Review Error:', err)
    return { valid: false, confidence: 0.0, issues: ['AI inceleme sırasında hata oluştu'] }
  }
}

const DRAFT_THRESHOLD = 0.85  // ≥ bu → draft (normal)
const DRAFT_FLAGGED_THRESHOLD = 0.60  // ≥ bu ama < 0.85 → draft_flagged

export async function runAIReview(jobId: string): Promise<{
  draft: number
  draftFlagged: number
  aiRejected: number
}> {
  const { data: questions, error } = await supabase
    .from('questions')
    .select('*, question_options(*)')
    .eq('generation_job_id', jobId)
    .eq('status', 'pending_ai_review')

  if (error || !questions) return { draft: 0, draftFlagged: 0, aiRejected: 0 }

  let draftCount = 0, draftFlaggedCount = 0, aiRejectedCount = 0

  for (const q of questions) {
    // Gemini 503 errors and rate limits are common, so we wait 1 second between reviews
    await new Promise(r => setTimeout(r, 1000))

    const review = await reviewSingleQuestion({
      body: q.body,
      explanation: q.explanation,
      correct_option: q.correct_option,
      question_options: q.question_options ?? [],
    })

    let newStatus: string
    if (review.confidence >= DRAFT_THRESHOLD && review.valid) {
      newStatus = 'draft'; draftCount++
    } else if (review.confidence >= DRAFT_FLAGGED_THRESHOLD) {
      newStatus = 'draft_flagged'; draftFlaggedCount++
    } else {
      newStatus = 'ai_rejected'; aiRejectedCount++
    }

    await supabase
      .from('questions')
      .update({
        status: newStatus,
        ai_review_score: review.confidence,
        ai_review_issues: review.issues.length > 0 ? review.issues : null,
        rejected_stage: newStatus === 'ai_rejected' ? 'ai_review' : null,
        rejection_reason: newStatus === 'ai_rejected'
          ? review.issues.join(' | ')
          : null,
      })
      .eq('id', q.id)
  }

  return { draft: draftCount, draftFlagged: draftFlaggedCount, aiRejected: aiRejectedCount }
}
