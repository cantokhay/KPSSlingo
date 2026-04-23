import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      console.error("Missing Authorization header");
      throw new Error("Missing Auth Header");
    }

    const supabaseUserClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await supabaseUserClient.auth.getUser();
    if (authError || !user) {
      console.error("Auth validation failed:", authError?.message || "No user found");
      throw new Error("Unauthorized");
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { lesson_id, answers } = await req.json();

    console.log(`Processing lesson results for user ${user.id}, lesson ${lesson_id}, answers count: ${answers?.length}`);

    // Tüm mantığı tek bir güvenli RPC'ye devret
    const { data: result, error: rpcError } = await supabase.rpc("process_lesson_results", {
      p_user_id: user.id,
      p_lesson_id: lesson_id,
      p_answers: answers
    });

    if (rpcError) {
      console.error("RPC Error in process_lesson_results:", rpcError);
      throw new Error(`RPC Error: ${rpcError.message}`);
    }

    return new Response(
      JSON.stringify(result),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err: any) {
    console.error("Edge Function Error:", err.message);
    return new Response(JSON.stringify({ error: err.message }), { 
      status: err.message === "Unauthorized" ? 401 : 400, 
      headers: corsHeaders 
    });
  }
});
