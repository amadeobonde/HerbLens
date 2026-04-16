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
    const { image_base64 } = await req.json()
    if (!image_base64) {
      return new Response(
        JSON.stringify({ error: "image_base64 is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const perplexityKey = Deno.env.get("PERPLEXITY_API_KEY")
    if (!perplexityKey) {
      throw new Error("PERPLEXITY_API_KEY not configured")
    }

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
            content: "You are a botanical expert. Identify the plant in the image and return JSON with: plant_name, confidence (0-1), scientific_name, properties (array of tags), and description. Be precise and cite sources.",
          },
          {
            role: "user",
            content: [
              { type: "text", text: "Identify this plant:" },
              { type: "image_url", image_url: { url: `data:image/jpeg;base64,${image_base64}` } },
            ],
          },
        ],
      }),
    })

    const result = await response.json()

    return new Response(
      JSON.stringify({
        identification: result.choices?.[0]?.message?.content,
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
