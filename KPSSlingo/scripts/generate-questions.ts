import { GoogleGenerativeAI } from "@google/generative-ai";
import { createClient } from "@supabase/supabase-js";
import * as crypto from "crypto";
import * as dotenv from "dotenv";

dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);
const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" }); // Trying a likely 2026 stable model

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

const SYSTEM_PROMPT = `Sen bir KPSS sınav uzmanısın. Görevin, verilen konu başlığı için orijinal, doğru ve eğitici çoktan seçmeli sorular üretmek.

KURALLAR:
1. Gerçek KPSS sorularını kopyalama — orijinal sorular üret.
2. Her soru KPSS müfredatına ve zorluk seviyesine uygun olsun.
3. Şıklar arasında sadece bir doğru cevap olsun.
4. Yanlış şıklar (çeldirici) mantıklı ve inandırıcı olsun.
5. Explanation alanına doğru cevabın neden doğru olduğunu açıkla.

YANIT FORMATI (sadece JSON, başka hiçbir şey yazma):
{
  "questions": [
    {
      "body": "Soru metni burada",
      "options": {
        "A": "Birinci şık",
        "B": "İkinci şık",
        "C": "Üçüncü şık",
        "D": "Dördüncü şık",
        "E": "Beşinci şık"
      },
      "correct_option": "A",
      "explanation": "Doğru cevabın açıklaması"
    }
  ]
}`;

async function generateQuestions(lessonId: string, lessonTitle: string, topicTitle: string, count = 10) {
  const userPrompt = `Konu: ${topicTitle} > ${lessonTitle}
Zorluk: Başlangıç seviyesi (beginner)
Soru Sayısı: ${count}

Bu ders için ${count} adet özgün KPSS sorusu üret.`;

  const promptHash = crypto.createHash("sha256").update(userPrompt).digest("hex");

  console.log(`Generating ${count} questions for ${lessonTitle}...`);

  const modelsToTry = [
    "models/gemini-3.1-flash-live-preview",
    "models/gemini-3.1-flash-lite-preview",
    "models/gemini-2.5-flash-native-audio-latest",
    "models/gemini-2.0-flash",
    "models/gemini-1.5-flash"
  ];

  let text = "";
  for (const modelName of modelsToTry) {
    try {
      console.log(`Trying model: ${modelName}...`);
      const model = genAI.getGenerativeModel({ model: modelName });
      const result = await model.generateContent({
        contents: [{ role: "user", parts: [{ text: SYSTEM_PROMPT + "\n\n" + userPrompt }] }],
      });
      const response = await result.response;
      text = response.text();
      if (text) break;
    } catch (e) {
      console.warn(`Model ${modelName} failed, trying next...`);
    }
  }

  if (!text) throw new Error("All Gemini models failed to generate content.");

  const jsonMatch = text.match(/\{[\s\S]*\}/);
  const parsed = JSON.parse(jsonMatch ? jsonMatch[0] : text);

  if (!parsed.questions) {
    throw new Error("Invalid response format from Gemini");
  }

  for (const q of parsed.questions) {
    // Soruyu ekle
    const { data: question, error } = await supabase
      .from("questions")
      .insert({
        lesson_id: lessonId,
        body: q.body,
        explanation: q.explanation,
        correct_option: q.correct_option,
        status: "draft",
        source: "ai_generated",
        ai_model: "gemini-1.5-flash",
        ai_prompt_hash: promptHash,
      })
      .select()
      .single();

    if (error || !question) {
      console.error("Soru eklenemedi:", error);
      continue;
    }

    // Şıkları ekle
    const optionRecords = Object.entries(q.options).map(([label, body]) => ({
      question_id: question.id,
      label,
      body,
    }));

    await supabase.from("question_options").insert(optionRecords);
    console.log(`✅ Soru eklendi (draft): ${q.body.substring(0, 50)}...`);
  }
}

// CLI
const args = process.argv.slice(2);
const lessonIdArg = args[args.indexOf("--lesson-id") + 1];
if (!lessonIdArg) {
  console.error("Kullanım: ts-node generate-questions.ts --lesson-id <uuid>");
  process.exit(1);
}

generateQuestions(lessonIdArg, "Dört İşlem", "Matematik");
