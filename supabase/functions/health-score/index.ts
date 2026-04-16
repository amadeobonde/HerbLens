import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get("Authorization")!
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const { plant_id } = await req.json()
    if (!plant_id) {
      return new Response(
        JSON.stringify({ error: "plant_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const [plantResult, profileResult] = await Promise.all([
      supabase.from("plants").select("*, plant_uses(*), plant_contraindications(*)").eq("id", plant_id).single(),
      supabase.from("health_profiles").select("*, health_goals(*)").eq("user_id", user.id).single(),
    ])

    if (plantResult.error) throw plantResult.error

    const plant = plantResult.data
    const healthProfile = profileResult.data

    const perplexityKey = Deno.env.get("PERPLEXITY_API_KEY")
    if (!perplexityKey) throw new Error("PERPLEXITY_API_KEY not configured")

    const response = await fetch("https://api.perplexity.ai/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${perplexityKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "sonar-pro",
        messages: [
          {
            role: "system",
            content: `You are a health assessment AI. Given a plant's properties and a user's health profile, compute a health relevance score (0-100). Return JSON: { overallScore: number, goalBreakdown: [{ goalName, relevanceScore, reason }], warnings: [{ type, severity, message }] }`,
          },
          {
            role: "user",
            content: JSON.stringify({ plant, healthProfile }),
          },
        ],
      }),
    })

    const result = await response.json()

    return new Response(
      JSON.stringify({
        health_score: result.choices?.[0]?.message?.content,
        citations: result.citations ?? [],
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  }
})
