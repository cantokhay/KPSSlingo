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
    const model = genAI.getGenerativeModel({ 
      model: "gemini-2.0-flash-latest",
      systemInstruction: `Sen bir KPSS eğitim asistanısın. Sana verilen soruları yanlış yapan öğrencilere teşvik edici ve açıklayıcı "mini analizler" yazarsın. Giriş veya sonuç cümlesi ekleme, doğrudan analizi yaz.`
    })

    const prompt = `
      Soru: ${question}
      Açıklama: ${explanation}

      Lütfen bu soruyu yanlış yapan bir öğrenci için 2-3 cümlelik kilit bir analiz yaz.
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
