import { GoogleGenerativeAI } from '@google/generative-ai'
import crypto from 'crypto'
import { callWithRetry } from './utils'
import { createClient } from '@supabase/supabase-js'
import { SYSTEM_PROMPT, FEW_SHOT_EXAMPLES, buildUserPrompt } from './prompts'
import { checkDuplicate } from './duplicate-check'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!)

const supabase = createClient(supabaseUrl, supabaseServiceKey)

interface GenerateParams {
  jobId: string
  lessonId: string
  topicSlug: string
  topicTitle: string
  lessonTitle: string
  count: number
  errorRate?: number | null
  rejectionContext?: { reason: string; note?: string }
}

interface GenerateResult {
  generated: number
  duplicatesSkipped: number
  errors: number
}

/**
 * Robust JSON extraction from LLM response
 * Handles markdown formatting and truncated responses
 */
function extractJSON(text: string) {
  let cleaned = text.trim()
  
  // Markdown temizliği
  cleaned = cleaned.replace(/^```json/g, '').replace(/```$/g, '').trim()

  try {
    return JSON.parse(cleaned)
  } catch (initialError: any) {
    console.warn('Initial JSON parse failed, attempting aggressive recovery...')
    
    // Geçerli bir JSON başlangıcı bul ({ veya [)
    const firstBrace = cleaned.indexOf('{')
    const firstBracket = cleaned.indexOf('[')
    const startIdx = (firstBrace !== -1 && (firstBracket === -1 || firstBrace < firstBracket)) ? firstBrace : firstBracket
    
    if (startIdx === -1) return null
    cleaned = cleaned.substring(startIdx)

    // Truncation (Kesilme) tamiri: Son geçerli nesne kapanışını bul
    // Eğer questions array'i içindeyse, son "}" karakterinden sonra "]}" ekleyerek kurtarabiliriz
    const lastObjectClose = cleaned.lastIndexOf('}')
    if (lastObjectClose !== -1) {
      let attempt = cleaned.substring(0, lastObjectClose + 1)
      
      // Eğer bir array içindeysek ve array kapanmadıysa kapat
      if (attempt.includes('[') && !attempt.includes(']')) attempt += ']}'
      else if (!attempt.endsWith('}')) attempt += '}'

      try {
        return JSON.parse(attempt)
      } catch (e) {
        // Son çare: Dengeli parantez ekleme
        let finalAttempt = attempt
        const openBraces = (finalAttempt.match(/\{/g) || []).length
        const closeBraces = (finalAttempt.match(/\}/g) || []).length
        const openBrackets = (finalAttempt.match(/\[/g) || []).length
        const closeBrackets = (finalAttempt.match(/\]/g) || []).length

        for (let i = 0; i < (openBraces - closeBraces); i++) finalAttempt += '}'
        for (let i = 0; i < (openBrackets - closeBrackets); i++) finalAttempt += ']'
        
        try {
          return JSON.parse(finalAttempt)
        } catch {
          return null
        }
      }
    }
    return null
  }
}

export async function generateQuestionsForLesson(
  params: GenerateParams
): Promise<GenerateResult> {
  const { jobId, lessonId, topicSlug, topicTitle, lessonTitle, count, errorRate, rejectionContext } = params

  const BATCH_SIZE = 5
  const iterations = Math.ceil(count / BATCH_SIZE)
  
  let totalGenerated = 0, totalDuplicatesSkipped = 0, totalErrors = 0

  for (let i = 0; i < iterations; i++) {
    const batchCount = Math.min(BATCH_SIZE, count - (i * BATCH_SIZE))
    console.log(`[Job ${jobId}] Generating batch ${i + 1}/${iterations} (${batchCount} questions) for ${lessonTitle}...`)

    const topicKey = Object.keys(FEW_SHOT_EXAMPLES).find(k => topicSlug.includes(k)) ?? ''
    const fewShotExample = FEW_SHOT_EXAMPLES[topicKey] ?? ''

    const systemWithExamples = fewShotExample
      ? `${SYSTEM_PROMPT}\n\n--- KALİTE REFERANSI ---\n${fewShotExample}`
      : SYSTEM_PROMPT

    const userPrompt = buildUserPrompt({ 
      topicTitle, 
      lessonTitle, 
      count: batchCount, 
      rejectionContext, 
      errorRateContext: errorRate 
    })

    let parsed: any
    try {
      const model = genAI.getGenerativeModel({ 
          model: 'gemini-flash-latest',
          systemInstruction: systemWithExamples,
          generationConfig: { 
            responseMimeType: "application/json",
            maxOutputTokens: 4096, 
            temperature: 0.7
          }
      })

      const result = await callWithRetry(() => model.generateContent(userPrompt))
      const text = result.response.text()
      parsed = extractJSON(text)
      
      if (!parsed || !parsed.questions) {
        console.error('Gemini invalid response:', text.substring(0, 500))
        totalErrors++
        continue
      }
    } catch (err) {
      console.error('Gemini API veya JSON parse hatası:', err)
      totalErrors++
      continue
    }

    for (const q of parsed.questions ?? []) {
      try {
        const bodyHash = crypto.createHash('sha256').update(q.body.trim()).digest('hex')
        const dupStatus = await checkDuplicate(bodyHash, q.body)
        
        if (dupStatus.isDuplicate) { 
          totalDuplicatesSkipped++
          continue 
        }

        const { data: question, error } = await supabase
          .from('questions')
          .insert({
            lesson_id: lessonId,
            body: q.body,
            explanation: q.explanation,
            status: 'generating',
            source: 'ai_generated',
            ai_model: 'gemini-flash-latest',
            body_hash: bodyHash,
            generation_job_id: jobId,
          })
          .select()
          .single()

        if (error || !question) { 
          console.error('Question insert error:', error)
          totalErrors++
          continue 
        }

        // Insert correct answer into secure table
        await supabase.from('question_answers').insert({
          question_id: question.id,
          correct_option: q.correct_option,
        })

        const optionRecords = Object.entries(q.options).map(([label, body]) => ({
          question_id: question.id,
          label,
          body: body as string,
        }))
        await supabase.from('question_options').insert(optionRecords)

        if (dupStatus.embedding) {
          await supabase.from('question_embeddings').insert({
            question_id: question.id,
            embedding: dupStatus.embedding,
          })
        }

        totalGenerated++
      } catch (err) {
        console.error('Processing single question error:', err)
        totalErrors++
      }
    }
  }

  return { 
    generated: totalGenerated, 
    duplicatesSkipped: totalDuplicatesSkipped, 
    errors: totalErrors 
  }
}
