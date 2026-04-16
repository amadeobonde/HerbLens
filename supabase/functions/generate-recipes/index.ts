import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"
import { getAccessToken, vertexUrl, corsHeaders } from "../_shared/vertex.ts"

/// Structured response schema so Gemini always returns valid JSON the iOS
/// client can decode into `[Recipe]` without repair steps.
const RECIPES_SCHEMA = {
  type: "object",
  properties: {
    recipes: {
      type: "array",
      minItems: 3,
      maxItems: 6,
      items: {
        type: "object",
        properties: {
          title: { type: "string" },
          type: { type: "string", enum: ["tea", "tincture"] },
          difficulty: { type: "string", enum: ["beginner", "intermediate", "advanced"] },
          prepTime: { type: "string" },
          steepOrCureTime: { type: "string" },
          yield: { type: "string" },
          accessTier: { type: "string", enum: ["free", "premium"] },
          ingredients: {
            type: "array",
            items: {
              type: "object",
              properties: {
                name: { type: "string" },
                amount: { type: "string" },
                notes: { type: "string" },
              },
              required: ["name", "amount"],
            },
          },
          steps: {
            type: "array",
            items: {
              type: "object",
              properties: {
                stepNumber: { type: "integer" },
                instruction: { type: "string" },
                tip: { type: "string" },
              },
              required: ["stepNumber", "instruction"],
            },
          },
        },
        required: ["title", "type", "difficulty", "prepTime", "yield", "accessTier", "ingredients", "steps"],
      },
    },
  },
  required: ["recipes"],
}

const SYSTEM_PROMPT = `You are an herbalist-AI for HerbLens. Given a plant, produce 3–5 safe, traditional recipes.

Rules (non-negotiable):
1. ONLY recipes using the plant the user is asking about. No foreign herbs.
2. Mix tea recipes with at least one tincture or syrup when the plant supports it.
3. Use steep/cure times grounded in real tradition — don't invent "45-day cures" without basis.
4. Every ingredient has a measured amount (e.g. "1 tbsp", "10 oz"), never "to taste" only.
5. Every step is one clear action. Avoid step-combining.
6. Mark recipes 'premium' if they require specialized equipment (pressure canner, precision thermometer),
   otherwise 'free'. Aim for roughly 2 free + 2 premium.
7. If the plant has well-known safety caveats (pregnancy, blood thinners, autoimmune),
   include them as a 'tip' on the relevant step — not a separate warnings block.
8. Titles are inviting and human, never clinical. "Evening Lemon Balm Tea" not "Melissa officinalis Herbal Infusion".
9. Difficulty: 'beginner' = steep or simmer only. 'intermediate' = multi-stage (e.g. syrup with double-strain).
   'advanced' = fermentation, oxymel, specialized tools.
10. Output MUST conform to the provided JSON schema exactly.`

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

    // Gating: premium users can generate on demand; free tier gets a hard cap of
    // 3 generations per day so Gemini costs don't spiral.
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const body = await req.json()
    const plantId: string | undefined = body.plant_id
    const plantName: string | undefined = body.plant_name
    if (!plantId && !plantName) {
      return new Response(
        JSON.stringify({ error: "plant_id or plant_name is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    // Hydrate the plant context. When given a plant_id we pull uses + contraindications
    // so Gemini grounds recipes in the actual herb. When given only plant_name we pass
    // it through — Gemini has strong priors for common culinary/medicinal herbs.
    let plantContext: Record<string, unknown> = plantName ? { commonName: plantName } : {}
    if (plantId) {
      const { data, error } = await supabase
        .from("plants")
        .select("common_name, alternate_names, description, tags, category, plant_uses(*), plant_contraindications(*)")
        .eq("id", plantId)
        .single()
      if (error) throw error
      plantContext = data
    }

    const { data: userProfile } = await supabase
      .from("user_profiles")
      .select("subscription_tier")
      .eq("id", user.id)
      .single()
    const tier = userProfile?.subscription_tier ?? "free"

    // Free-tier quota: cap at 3 generations per calendar day, same pattern as scans.
    if (tier === "free") {
      const startOfDay = new Date()
      startOfDay.setUTCHours(0, 0, 0, 0)
      const { count } = await supabase
        .from("recipe_generations")
        .select("id", { count: "exact", head: true })
        .eq("user_id", user.id)
        .gte("generated_at", startOfDay.toISOString())
      if ((count ?? 0) >= 3) {
        return new Response(
          JSON.stringify({ error: "quota_exceeded", limit: 3 }),
          { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        )
      }
    }

    // Premium users get Gemini 3 Pro for richer recipe variety.
    const model = tier === "premium" ? "gemini-3-pro-preview" : "gemini-3-flash-preview"
    const token = await getAccessToken()
    const endpoint = vertexUrl(model, "generateContent")

    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        systemInstruction: { role: "user", parts: [{ text: SYSTEM_PROMPT }] },
        contents: [{
          role: "user",
          parts: [{ text: JSON.stringify(plantContext) }],
        }],
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: RECIPES_SCHEMA,
          temperature: 0.4,
        },
      }),
    })

    if (!response.ok) {
      const errText = await response.text()
      throw new Error(`Vertex error ${response.status}: ${errText}`)
    }

    const result = await response.json()
    const content = result.candidates?.[0]?.content?.parts?.[0]?.text
    const parsed = content ? JSON.parse(content) : null

    // Stamp each recipe with a stable UUID so the iOS client can cache locally.
    const recipes = (parsed?.recipes ?? []).map((r: Record<string, unknown>) => ({
      id: crypto.randomUUID(),
      ...r,
    }))

    // Log the generation for quota accounting. Schema migration lands separately.
    await supabase.from("recipe_generations").insert({
      user_id: user.id,
      plant_id: plantId ?? null,
      plant_name: plantContext.commonName ?? plantName ?? null,
      model,
      count: recipes.length,
    })

    return new Response(
      JSON.stringify({ recipes }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  }
})
