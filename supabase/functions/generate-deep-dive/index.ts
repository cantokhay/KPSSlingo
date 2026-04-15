import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.1.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const { questionBody, correctAnswer, selectedAnswer } = await req.json();

    const genAI = new GoogleGenerativeAI(Deno.env.get("GEMINI_API_KEY")!);
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash-latest" });

    const prompt = `
      Sen bir KPSS uzmanısın. Kullanıcı şu soruya ${selectedAnswer === correctAnswer ? 'doğru' : 'yanlış'} cevap verdi.
      Soru: "${questionBody}"
      Doğru Cevap: "${correctAnswer}"
      Kullanıcının Cevabı: "${selectedAnswer}"

      GÖREVİN:
      Kullanıcıya bu sorunun mantığını, neden doğru cevabın o olduğunu ve diğer şıkların neden çeldirici olduğunu profesyonel ama samimi bir dille, 2-3 kısa paragrafta açıkla. 
      KPSS'de bu tarz sorularda neye dikkat etmeleri gerektiğini belirten bir "İpucu" ile bitir.
      Yanıtını doğrudan metin olarak ver.
    `;

    const result = await model.generateContent(prompt);
    const text = result.response.text();

    return new Response(JSON.stringify({ text }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: corsHeaders,
    });
  }
});
