// Nano Banana — Google's image generation + edit model (gemini-2.5-flash-image).
// Use for static imagery: collection covers, recipe hero shots, mascot variants,
// empty-state art. Returns a base64 PNG that the iOS app can persist or display.

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
    const authHeader = req.headers.get("Authorization")
    if (authHeader) {
      const supabase = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_ANON_KEY")!,
        { global: { headers: { Authorization: authHeader } } },
      )
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) {
        return new Response(
          JSON.stringify({ error: "Unauthorized" }),
          { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        )
      }
    }

    const { prompt, reference_image_base64, reference_mime_type } = await req.json()
    if (!prompt || typeof prompt !== "string") {
      return new Response(
        JSON.stringify({ error: "prompt is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const geminiKey = Deno.env.get("GEMINI_API_KEY")
    if (!geminiKey) throw new Error("GEMINI_API_KEY not configured")

    const parts: any[] = [{ text: prompt }]
    if (reference_image_base64) {
      parts.push({
        inlineData: {
          mimeType: reference_mime_type ?? "image/jpeg",
          data: reference_image_base64,
        },
      })
    }

    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=${geminiKey}`

    const response = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts }],
      }),
    })

    if (!response.ok) {
      const errText = await response.text()
      throw new Error(`Nano Banana error ${response.status}: ${errText}`)
    }

    const result = await response.json()
    const imagePart = result.candidates?.[0]?.content?.parts?.find((p: any) => p.inlineData)
    if (!imagePart) throw new Error("No image returned from Nano Banana")

    return new Response(
      JSON.stringify({
        image_base64: imagePart.inlineData.data,
        mime_type: imagePart.inlineData.mimeType ?? "image/png",
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
