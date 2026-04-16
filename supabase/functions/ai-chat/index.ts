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

    const { messages, context_plant_id } = await req.json()
    if (!messages || !Array.isArray(messages)) {
      return new Response(
        JSON.stringify({ error: "messages array is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    let plantContext = ""
    if (context_plant_id) {
      const { data: plant } = await supabase
        .from("plants")
        .select("*, plant_uses(*), plant_contraindications(*)")
        .eq("id", context_plant_id)
        .single()
      if (plant) {
        plantContext = `\n\nContext plant: ${plant.common_name}. Uses: ${plant.plant_uses?.map((u: any) => u.description).join("; ")}. Contraindications: ${plant.plant_contraindications?.map((c: any) => `${c.condition}: ${c.details}`).join("; ")}.`
      }
    }

    const { data: healthProfile } = await supabase
      .from("health_profiles")
      .select("*, health_goals(*)")
      .eq("user_id", user.id)
      .single()

    let healthContext = ""
    if (healthProfile) {
      healthContext = `\n\nUser health profile: Goals: ${healthProfile.health_goals?.map((g: any) => g.name).join(", ")}. Allergies: ${healthProfile.allergies?.join(", ") || "none"}. Medications: ${healthProfile.medications?.join(", ") || "none"}. Conditions: ${healthProfile.conditions?.join(", ") || "none"}.`
    }

    const perplexityKey = Deno.env.get("PERPLEXITY_API_KEY")
    if (!perplexityKey) throw new Error("PERPLEXITY_API_KEY not configured")

    const systemMessage = `You are Bamboo, a friendly and knowledgeable herbal medicine expert panda. You help users learn about herbs, teas, tinctures, and natural remedies. Always cite sources. Warn about contraindications and drug interactions. Be warm but scientifically accurate.${plantContext}${healthContext}`

    const response = await fetch("https://api.perplexity.ai/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${perplexityKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "sonar-pro",
        messages: [
          { role: "system", content: systemMessage },
          ...messages,
        ],
      }),
    })

    const result = await response.json()

    return new Response(
      JSON.stringify({
        message: result.choices?.[0]?.message?.content,
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
