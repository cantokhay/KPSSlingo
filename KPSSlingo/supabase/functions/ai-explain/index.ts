import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { GoogleGenerativeAI } from "npm:@google/generative-ai"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { question, explanation } = await req.json()
    
    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!)
    const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash-latest" })

    const prompt = `
      Sana bir KPSS sorusu ve açıklaması verilecek. 
      Soru: ${question}
      Açıklama: ${explanation}

      Lütfen bu soruyu yanlış yapan bir öğrenciye, konuyu daha iyi kavraması için 2-3 cümlelik "mini bir analiz" yaz. 
      Analiz; neden bu cevabın doğru olduğunu, konunun kilit noktasını ve öğrencinin bir dahaki sefere neye dikkat etmesi gerektiğini içermeli. 
      Dil samimi ve teşvik edici olsun. Sadece analizi yaz, giriş veya sonuç cümlesi ekleme.
    `

    const result = await model.generateContent(prompt)
    const analysis = result.response.text().trim()

    return new Response(
      JSON.stringify({ analysis }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
