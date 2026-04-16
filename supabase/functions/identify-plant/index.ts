import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { getAccessToken, vertexUrl, corsHeaders } from "../_shared/vertex.ts"

const IDENTIFY_SCHEMA = {
  type: "object",
  properties: {
    plant_name: { type: "string" },
    confidence: { type: "number" },
    scientific_name: { type: "string" },
    properties: { type: "array", items: { type: "string" } },
    description: { type: "string" },
    candidates: {
      type: "array",
      items: {
        type: "object",
        properties: {
          plant_name: { type: "string" },
          confidence: { type: "number" },
          scientific_name: { type: "string" },
        },
        required: ["plant_name", "confidence", "scientific_name"],
      },
    },
  },
  required: ["plant_name", "confidence", "scientific_name", "description"],
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const { image_base64, mime_type } = await req.json()
    if (!image_base64) {
      return new Response(
        JSON.stringify({ error: "image_base64 is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const token = await getAccessToken()
    const endpoint = vertexUrl("gemini-3-flash-preview", "generateContent")

    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        systemInstruction: {
          role: "user",
          parts: [{
            text: "You are a botanical expert. Identify the plant in the image. Return the top match plus up to 2 alternate candidates when confidence < 0.75. Be precise and conservative with confidence. Never fabricate scientific names.",
          }],
        },
        contents: [{
          role: "user",
          parts: [
            { text: "Identify this plant." },
            { inlineData: { mimeType: mime_type ?? "image/jpeg", data: image_base64 } },
          ],
        }],
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: IDENTIFY_SCHEMA,
          temperature: 0.2,
          thinkingConfig: { thinkingBudget: 512 },
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

    return new Response(
      JSON.stringify({ identification: parsed }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  }
})
