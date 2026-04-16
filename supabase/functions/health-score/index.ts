import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const HEALTH_SCORE_SCHEMA = {
  type: "object",
  properties: {
    overallScore: { type: "integer" },
    goalBreakdown: {
      type: "array",
      items: {
        type: "object",
        properties: {
          goalName: { type: "string" },
          relevanceScore: { type: "integer" },
          reason: { type: "string" },
        },
        required: ["goalName", "relevanceScore", "reason"],
      },
    },
    warnings: {
      type: "array",
      items: {
        type: "object",
        properties: {
          type: { type: "string", enum: ["allergy", "medication_interaction", "condition"] },
          severity: { type: "string", enum: ["low", "moderate", "high"] },
          message: { type: "string" },
        },
        required: ["type", "severity", "message"],
      },
    },
  },
  required: ["overallScore", "goalBreakdown", "warnings"],
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

    const geminiKey = Deno.env.get("GEMINI_API_KEY")
    if (!geminiKey) throw new Error("GEMINI_API_KEY not configured")

    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiKey}`

    const response = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        systemInstruction: {
          role: "user",
          parts: [{
            text: "You are a health assessment AI. Given a plant's properties and a user's health profile, compute a health relevance score (0-100). Break it down per user health goal with a relevance score and a short reason grounded in the plant's known uses. Always surface warnings when the plant's contraindications overlap the user's allergies, medications, or conditions. Be conservative — when unsure, lower the score and add a warning.",
          }],
        },
        contents: [{
          role: "user",
          parts: [{ text: JSON.stringify({ plant, healthProfile }) }],
        }],
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: HEALTH_SCORE_SCHEMA,
          temperature: 0.1,
        },
      }),
    })

    if (!response.ok) {
      const errText = await response.text()
      throw new Error(`Gemini error ${response.status}: ${errText}`)
    }

    const result = await response.json()
    const content = result.candidates?.[0]?.content?.parts?.[0]?.text
    const parsed = content ? JSON.parse(content) : null

    return new Response(
      JSON.stringify({ health_score: parsed }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  }
})
