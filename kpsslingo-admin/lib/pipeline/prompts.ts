export const SYSTEM_PROMPT = `GÖREVİN:
Verilen konu ve ders için, KPSS'ye hazırlanan adaylara yönelik, KISA ve ÖZ, FLASHCARD (ezberlemelik) tarzında, doğrudan bilgi ölçen özgün çoktan seçmeli sorular üretmek.

ZORUNLU KURALLAR:
1. SORULAR KISA OLMALI — Soru metni tek cümlelik, doğrudan bilgi soran yapıda olmalı.
2. FLASHCARD TARZI — Gereksiz detaydan kaçın, en temel ve can alıcı bilgileri sorgula.
3. KALİTE HEDEFİ — Sorular ne çok kolay ne de çok zor (ortalama 4-7 puan kalitesinde) olmalı.
4. GERÇEK KPSS SORULARINI KOPYALAMA — Her soru tamamen özgün olmalı.
5. Her soruda tam olarak 5 şık (A, B, C, D, E) bulunmalı.
6. Yalnızca bir doğru cevap olmalı; diğer şıklar inandırıcı çeldiriciler içermeli.
7. Explanation (açıklama) kısa ve net olmalı, bilginin neden doğru olduğunu bir cümleyle açıklamalı.
8. Türkçe dilbilgisi kurallarına uy.
9. Soru metni içinde doğru cevabı ima eden ipucu bırakma.

ÇIKTI FORMATI (YALNIZCA geçerli JSON formatında yanıt ver, başka hiçbir metin ekleme):
{
  "questions": [
    {
      "body": "Soru metni burada yer alır?",
      "options": {
        "A": "Birinci şık",
        "B": "İkinci şık",
        "C": "Üçüncü şık",
        "D": "Dördüncü şık",
        "E": "Beşinci şık"
      },
      "correct_option": "C",
      "explanation": "C şıkkı doğrudur çünkü..."
    }
  ]
}`

// Konu gruplarına göre few-shot örnekler
export const FEW_SHOT_EXAMPLES: Record<string, string> = {
  'matematik': `
ÖRNEK İYİ SORU:
{
  "body": "Bir işçi bir işin 1/4'ünü 3 günde yapabilmektedir. Aynı işçi bu işin tamamını kaç günde bitirir?",
  "options": { "A": "8", "B": "10", "C": "12", "D": "15", "E": "16" },
  "correct_option": "C",
  "explanation": "İşçi 1/4'ünü 3 günde yaptığına göre tamamını 3 × 4 = 12 günde bitirir."
}`,

  'turkce': `
ÖRNEK İYİ SORU:
{
  "body": "Aşağıdaki cümlelerin hangisinde 'de/da' bağlacı yanlış kullanılmıştır?",
  "options": {
    "A": "Sen de mi geliyorsun?",
    "B": "Hava da güzeldi.",
    "C": "Kitabı da aldı, defteri de.",
    "D": "O da bilmiyordu.",
    "E": "Çocuklar da oyun oynuyor."
  },
  "correct_option": "B",
  "explanation": "'Hava da güzeldi' cümlesinde 'da' pekiştirme görevinde kullanılmakla birlikte ayrı yazılmalıdır. Bu seçenekte bağlaç işlevi tam anlamıyla gerçekleşmemektedir."
}`,

  'tarih': `
ÖRNEK İYİ SORU:
{
  "body": "Lozan Antlaşması'nın imzalanmasının Türkiye açısından en önemli sonucu hangisidir?",
  "options": {
    "A": "Kapitülasyonların kaldırılması",
    "B": "Ulusal sınırların uluslararası alanda tanınması",
    "C": "İstanbul'un Türkiye'ye bırakılması",
    "D": "Osmanlı borçlarının silinmesi",
    "E": "Boğazlar üzerinde tam egemenlik sağlanması"
  },
  "correct_option": "B",
  "explanation": "Lozan Antlaşması ile Türkiye Cumhuriyeti'nin sınırları uluslararası kamuoyu tarafından resmen tanınmış, böylece Misak-ı Millî'nin önemli bir kısmı hayata geçirilmiştir."
}`
}

function sanitizeInput(text: string): string {
  // Sadece alfanumerik, boşluk ve temel Türkçeye özgü karakterler ile noktalama işaretlerini bırak
  return text.replace(/[^\w\sğüşöçıİĞÜŞÖÇ.,?!-]/gi, '').trim();
}

export function buildUserPrompt(params: {
  topicTitle: string
  lessonTitle: string
  count: number
  rejectionContext?: { reason: string; note?: string }
  errorRateContext?: number | null
}): string {
  const { topicTitle, lessonTitle, count, rejectionContext, errorRateContext } = params

  const safeTopic = sanitizeInput(topicTitle)
  const safeLesson = sanitizeInput(lessonTitle)

  let prompt = `Konu: ${safeTopic}
Ders: ${safeLesson}
Zorluk: Başlangıç seviyesi (beginner)
Üretilecek Soru Sayısı: ${count}
`

  // Hata oranı varsa ek bağlam
  if (errorRateContext !== null && errorRateContext !== undefined) {
    prompt += `\nNOT: Bu konuda kullanıcıların hata oranı %${Math.round(errorRateContext * 100)}'dir. Konunun zor noktalarına odaklanan, anlam karışıklığı yaratan kavramları test eden sorular üret.\n`
  }

  // Yeniden üretim bağlamı
  if (rejectionContext) {
    prompt += `\nYENİDEN ÜRETİM BAĞLAMI:
Daha önce üretilen bir soru şu nedenle reddedildi: "${rejectionContext.reason}"
${rejectionContext.note ? `Admin notu: "${rejectionContext.note}"` : ''}
Bu hatadan kaçınan, farklı bir açıdan yaklaşan sorular üret.\n`
  }

  prompt += `\nBu kriterlere uygun ${count} adet özgün KPSS sorusu üret. Yalnızca JSON formatında yanıt ver.`
  return prompt
}

export const AI_REVIEW_SYSTEM = `Sen bir KPSS sınav kalite kontrol uzmanısın. Sana verilen çoktan seçmeli soruyu aşağıdaki kriterlere göre değerlendir.

DEĞERLENDİRME KRİTERLERİ:
1. Faktüel doğruluk: Soru ve cevap bilimsel/tarihsel olarak doğru mu?
2. Net ve anlaşılır: Soru tek bir anlama geliyor mu?
3. Tek doğru cevap: Sadece bir şık kesinlikle doğru mu?
4. Çeldirici kalitesi: Yanlış şıklar inandırıcı ve mantıklı mı?
5. Müfredat uyumu: Soru KPSS Genel Yetenek/Genel Kültür kapsamında mı?
6. Açıklama kalitesi: Explanation neden doğru olduğunu açıklıyor mu?

YANIT FORMATI (YALNIZCA geçerli JSON formatında yanıt ver):
{
  "valid": true,
  "confidence": 0.92,
  "issues": []
}
veya
{
  "valid": false,
  "confidence": 0.45,
  "issues": ["Faktüel hata: X yanlış", "Birden fazla doğru cevap mümkün"]
}`
