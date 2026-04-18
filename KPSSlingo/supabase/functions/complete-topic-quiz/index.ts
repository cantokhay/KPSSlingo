import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing Auth Header" }), { status: 401, headers: corsHeaders });
  }

  const supabaseUserClient = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    { global: { headers: { Authorization: authHeader } } }
  );

  const { data: { user }, error: authError } = await supabaseUserClient.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const { topic_id, answers } = await req.json();
  // answers: Array<{ question_id: string, selected_option: string, time_spent_ms: number }>

  // 1. Soruların doğru cevaplarını çek
  const questionIds = answers.map((a: any) => a.question_id);
  const { data: questions } = await supabase
    .from("questions")
    .select("id, correct_option, lesson_id")
    .in("id", questionIds);

  if (!questions) return new Response(JSON.stringify({ error: "Questions not found" }), { status: 400, headers: corsHeaders });

  // 2. Cevapları değerlendir
  const answerRecords = answers.map((a: any) => {
    const q = questions.find((q: any) => q.id === a.question_id);
    return {
      user_id: user.id,
      question_id: a.question_id,
      lesson_id: q?.lesson_id, // Get lesson_id from question to maintain links
      selected_option: a.selected_option,
      is_correct: q?.correct_option === a.selected_option,
      time_spent_ms: a.time_spent_ms,
    };
  });

  const correctCount = answerRecords.filter((a: any) => a.is_correct).length;
  const score = Math.round((correctCount / answers.length) * 100);

  // 3. Cevapları kaydet
  await supabase.from("user_question_answers").insert(answerRecords);

  // 4. questions tablosundaki istatistikleri güncelle (denormalized)
  for (const a of answerRecords) {
    await supabase.rpc("increment_question_stats", {
      q_id: a.question_id,
      is_correct: a.is_correct,
    });
  }

  // 5. User performance güncelle (Topic bazlı)
  await supabase.rpc("update_user_performance", {
    p_user_id: user.id,
    p_topic_id: topic_id,
    p_correct_count: correctCount,
    p_total_count: answers.length,
  });

  // 6. Bonus XP kazanımı (Rastgele çözene daha çok XP: 25 XP)
  const xpEarned = 25; 

  // XP ve level güncelle
  await supabase.rpc("add_xp_to_user", {
    user_uuid: user.id,
    xp_amount: xpEarned,
  });

  // 7. Streak güncelle
  const today = new Date().toISOString().split("T")[0];
  const { data: streak } = await supabase
    .from("streaks")
    .select("*")
    .eq("user_id", user.id)
    .single();

  let newStreak = 1;
  if (streak) {
    const lastDate = streak.last_activity_date;
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split("T")[0];

    if (lastDate === today) {
      newStreak = streak.current_streak; // Bugün zaten çalışmış
    } else if (lastDate === yesterdayStr) {
      newStreak = streak.current_streak + 1; // Dün çalışmış, seri devam
    } else {
      newStreak = 1; // Seri koptu
    }
  }

  await supabase.from("streaks").upsert({
    user_id: user.id,
    current_streak: newStreak,
    longest_streak: Math.max(newStreak, streak?.longest_streak ?? 0),
    last_activity_date: today,
  });

  return new Response(
    JSON.stringify({ score, xp_earned: xpEarned, streak: newStreak }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" } }
  );
});
