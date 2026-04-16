import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const MAX_HEARTS = 15;
const REGEN_INTERNAL_MS = 15 * 1000; // 15 seconds

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
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

    // 1. Kullanıcı profilini çek
    const { data: profile, error: profileError } = await supabase
      .from("user_profiles")
      .select("hearts, last_heart_regen, total_xp, current_level, onboarding_complete")
      .eq("id", user.id)
      .single();

    if (profileError || !profile) {
      return new Response(JSON.stringify({ error: "Profile not found" }), { status: 404, headers: corsHeaders });
    }

    const now = new Date();
    const lastRegen = new Date(profile.last_heart_regen || now);
    const timePassedMs = now.getTime() - lastRegen.getTime();

    let currentHearts = profile.hearts ?? MAX_HEARTS;
    let newLastRegen = lastRegen;

    if (currentHearts < MAX_HEARTS) {
      const heartsToAdd = Math.floor(timePassedMs / REGEN_INTERNAL_MS);
      if (heartsToAdd > 0) {
        currentHearts = Math.min(MAX_HEARTS, currentHearts + heartsToAdd);
        
        // Eğer fullediysek regen vaktini 'şimdi' yapıyoruz
        if (currentHearts === MAX_HEARTS) {
          newLastRegen = now;
        } else {
          // Fulleyemediysek, sadece eklediğimiz canların vaktini ekliyoruz 
          // (artık kalan dakikalar yanmasın diye)
          newLastRegen = new Date(lastRegen.getTime() + (heartsToAdd * REGEN_INTERNAL_MS));
        }

        // Güncelle
        await supabase
          .from("user_profiles")
          .update({
            hearts: currentHearts,
            last_heart_regen: newLastRegen.toISOString()
          })
          .eq("id", user.id);
      }
    } else {
      // Canlar zaten doluysa regen vaktini güncel tutalım
      newLastRegen = now;
      if (profile.last_heart_regen !== newLastRegen.toISOString()) {
         await supabase
          .from("user_profiles")
          .update({ last_heart_regen: newLastRegen.toISOString() })
          .eq("id", user.id);
      }
    }

    // 2. Diğer state verilerini de çekip dönelim (sync purposes)
    const { data: streaks } = await supabase
      .from("streaks")
      .select("current_streak, last_activity_date")
      .eq("user_id", user.id)
      .single();

    return new Response(
      JSON.stringify({
        profile: {
          ...profile,
          hearts: currentHearts,
          last_heart_regen: newLastRegen.toISOString()
        },
        streak: streaks?.current_streak ?? 0,
        server_time: now.toISOString()
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: corsHeaders });
  }
});
