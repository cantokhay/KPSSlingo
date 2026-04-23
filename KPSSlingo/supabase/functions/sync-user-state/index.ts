import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const MAX_HEARTS = 15;
const REGEN_INTERNAL_MS = 30 * 1000; // 30 seconds

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

    // Can yenilenmesini sunucu tarafında güvenli bir şekilde yap
    const { data: syncData, error: syncError } = await supabase.rpc("sync_user_hearts", {
      p_user_id: user.id
    });

    if (syncError) {
      throw new Error(`Sync Error: ${syncError.message}`);
    }

    const { current_hearts, last_regen, server_time } = syncData[0];
    
    // Profili tekrar çek (XP ve diğer bilgiler için)
    const { data: profile } = await supabase
      .from("user_profiles")
      .select("*")
      .eq("id", user.id)
      .single();

    const { data: streaks } = await supabase
      .from("streaks")
      .select("current_streak, last_activity_date")
      .eq("user_id", user.id)
      .maybeSingle();

    return new Response(
      JSON.stringify({
        profile: {
          ...profile,
          hearts: current_hearts,
          last_heart_regen: last_regen
        },
        streak: streaks?.current_streak ?? 0,
        server_time: server_time
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: corsHeaders });
  }
});

