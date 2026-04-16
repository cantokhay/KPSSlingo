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

  const { lesson_id, answers } = await req.json();
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
      lesson_id,
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

  // 5. user_progress güncelle (upsert)
  const { data: existingProgress } = await supabase
    .from("user_progress")
    .select("best_score, attempt_count")
    .eq("user_id", user.id)
    .eq("lesson_id", lesson_id)
    .single();

  await supabase.from("user_progress").upsert({
    user_id: user.id,
    lesson_id,
    status: "completed",
    score,
    best_score: Math.max(score, existingProgress?.best_score ?? 0),
    attempt_count: (existingProgress?.attempt_count ?? 0) + 1,
    completed_at: new Date().toISOString(),
  }, { onConflict: "user_id,lesson_id" });

  // 6. Ders detaylarını al (XP ve Topic ID)
  const { data: lesson } = await supabase
    .from("lessons")
    .select("xp_reward, topic_id")
    .eq("id", lesson_id)
    .single();

  if (lesson) {
    // 6.1 Analitik güncelle
    await supabase.rpc("update_user_performance", {
      p_user_id: user.id,
      p_topic_id: lesson.topic_id,
      p_correct_count: correctCount,
      p_total_count: answers.length,
    });
  }

  const xpEarned = lesson?.xp_reward ?? 10;

  // 7. XP ve level güncelle
  await supabase.rpc("add_xp_to_user", {
    user_uuid: user.id,
    xp_amount: xpEarned,
  });

  // 8. Streak güncelle
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
