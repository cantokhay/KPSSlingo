import { createClient } from '@supabase/supabase-js'
import { GoogleGenerativeAI } from '@google/generative-ai'
import { callWithRetry } from './utils'
import crypto from 'crypto'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!)

const supabase = createClient(supabaseUrl, supabaseServiceKey)

const COSINE_SIMILARITY_THRESHOLD = 0.92  // Bu üstü = duplicate

export async function checkDuplicate(
  bodyHash: string,
  bodyText: string
): Promise<{ isDuplicate: boolean; embedding?: number[] }> {
  // ── KAT 1: Hash kontrolü (O(1), hızlı) ──────────────────────────────────
  const { data: hashMatch } = await supabase
    .from('questions')
    .select('id')
    .eq('body_hash', bodyHash)
    .not('status', 'eq', 'archived')
    .limit(1)
    .maybeSingle()

  if (hashMatch) return { isDuplicate: true }

  // ── KAT 2: Embedding benzerlik kontrolü ─────────────────────────────────
  let embedding: number[] = []
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-embedding-001' })
    const result = await callWithRetry(() => model.embedContent(bodyText))
    embedding = result.embedding.values
  } catch (err) {
    console.error('Error generating embedding:', err)
    // If embedding fails, we proceed with hash only but log it
    return { isDuplicate: false }
  }

  // pgvector cosine similarity sorgusu
  const { data: similar, error: rpcError } = await supabase.rpc('find_similar_questions', {
    query_embedding: embedding,
    similarity_threshold: COSINE_SIMILARITY_THRESHOLD,
    match_count: 1,
  })

  if (rpcError) {
    console.error('Error calling find_similar_questions RPC:', rpcError)
  }

  if (similar && similar.length > 0) return { isDuplicate: true }

  return { isDuplicate: false, embedding }
}
