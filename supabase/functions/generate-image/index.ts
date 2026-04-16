// Image generation — HerbLens brand assets (dev-time only).
//
// Two upstream models:
//   - Nano Banana 2 (gemini-3.1-flash-image-preview) for mascots, recipes,
//     empty states. Supports transparent PNG when prompted explicitly.
//   - Imagen 4 Ultra (imagen-4.0-ultra-generate-001) for hero/editorial
//     shots. Solid backgrounds only; higher photoreal fidelity.
//
// Request shape:
//   { prompt: string,
//     variant?: "nano" | "imagen-ultra",        // default "nano"
//     transparent?: boolean,                     // default false (nano only)
//     reference_image_base64?: string,           // optional reference (nano only)
//     reference_mime_type?: string,
//     apply_brand_style?: boolean,               // default true — append BRAND_STYLE + NEGATIVE_PROMPT
//     aspect_ratio?: "1:1"|"16:9"|"9:16"|"4:3"|"3:4" }
//
// Response: { image_base64, mime_type, model, prompt_sent }

import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { getAccessToken, vertexUrl, corsHeaders } from "../_shared/vertex.ts"
import {
  BAMBOO_CHARACTER_SHEET,
  BRAND_STYLE,
  NEGATIVE_PROMPT,
  TRANSPARENT_BG_DIRECTIVE,
  THEMED_BG_DIRECTIVE,
} from "../_shared/brand.ts"

// Gemini image models — on Vertex AI these live in the `global` location,
// and the Developer-API names differ from the Vertex names. Mapping:
//   Dev API                           │ Vertex AI                        │ Notes
//   gemini-2.5-flash-image            │ gemini-2.5-flash-image           │ Nano Banana 1, $0.039/image
//   gemini-3.1-flash-image-preview    │ gemini-3-pro-image-preview       │ Nano Banana 2 / Gemini 3 Pro Image, $0.134/image (1-2K)
const NANO_MODEL = "gemini-2.5-flash-image"       // cheap, fast, great quality
const PRO_IMAGE_MODEL = "gemini-3-pro-image-preview" // top-tier Gemini image
const IMAGEN_ULTRA_MODEL = "imagen-4.0-ultra-generate-001"
const GEMINI_IMAGE_LOCATION = "global"
const IMAGEN_LOCATION = "us-central1"

function buildPrompt(
  userPrompt: string,
  opts: { applyBrand: boolean; transparent: boolean; includeMascot: boolean },
): string {
  if (!opts.applyBrand) return userPrompt
  const bg = opts.transparent ? TRANSPARENT_BG_DIRECTIVE : THEMED_BG_DIRECTIVE
  const sections = [
    userPrompt,
    "",
    "--- STYLE GUIDE (mandatory) ---",
    BRAND_STYLE,
  ]
  if (opts.includeMascot) {
    sections.push("", "--- MASCOT CHARACTER SHEET (mandatory consistency) ---", BAMBOO_CHARACTER_SHEET)
  }
  sections.push(
    "",
    "--- BACKGROUND ---",
    bg,
    "",
    "--- NEGATIVE (must NOT appear) ---",
    NEGATIVE_PROMPT,
  )
  return sections.join("\n")
}

async function generateWithGeminiImage(
  model: string,
  token: string,
  prompt: string,
  aspectRatio: string,
  referenceImage?: { data: string; mimeType: string },
): Promise<{ data: string; mimeType: string }> {
  const parts: unknown[] = [{ text: prompt }]
  if (referenceImage) {
    parts.push({ inlineData: { mimeType: referenceImage.mimeType, data: referenceImage.data } })
  }
  const response = await fetch(vertexUrl(model, "generateContent", GEMINI_IMAGE_LOCATION), {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      contents: [{ role: "user", parts }],
      generationConfig: {
        responseModalities: ["IMAGE"],
        imageConfig: {
          aspectRatio,
          imageSize: "2K",
        },
      },
    }),
  })
  if (!response.ok) {
    throw new Error(`Gemini image (${model}) error ${response.status}: ${await response.text()}`)
  }
  const result = await response.json()
  const imagePart = result.candidates?.[0]?.content?.parts?.find((p: { inlineData?: unknown }) => p.inlineData)
  if (!imagePart) throw new Error(`No image returned from ${model}`)
  return {
    data: imagePart.inlineData.data,
    mimeType: imagePart.inlineData.mimeType ?? "image/png",
  }
}

async function generateWithImagenUltra(
  token: string,
  prompt: string,
  aspectRatio: string,
): Promise<{ data: string; mimeType: string }> {
  const response = await fetch(vertexUrl(IMAGEN_ULTRA_MODEL, "predict", IMAGEN_LOCATION), {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      instances: [{ prompt }],
      parameters: {
        sampleCount: 1,
        aspectRatio,
        personGeneration: "allow_adult",
        addWatermark: false,
        safetySetting: "block_only_high",
        enhancePrompt: true,
        sampleImageSize: "2K",
      },
    }),
  })
  if (!response.ok) {
    throw new Error(`Imagen 4 Ultra error ${response.status}: ${await response.text()}`)
  }
  const result = await response.json()
  const prediction = result.predictions?.[0]
  if (!prediction?.bytesBase64Encoded) {
    throw new Error("No image returned from Imagen 4 Ultra")
  }
  return {
    data: prediction.bytesBase64Encoded,
    mimeType: prediction.mimeType ?? "image/png",
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    // Dev-time image gen — JWT verification is handled by the edge runtime
    // itself (anon key is a valid JWT). No user session required.

    const {
      prompt,
      variant = "nano",
      transparent = false,
      reference_image_base64,
      reference_mime_type,
      apply_brand_style = true,
      include_mascot = false,
      aspect_ratio = "1:1",
    } = await req.json()

    if (!prompt || typeof prompt !== "string") {
      return new Response(
        JSON.stringify({ error: "prompt is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    if (variant === "imagen-ultra" && transparent) {
      return new Response(
        JSON.stringify({ error: "Imagen 4 Ultra does not support transparent backgrounds — use variant=nano or pro-image" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const fullPrompt = buildPrompt(prompt, {
      applyBrand: apply_brand_style,
      transparent,
      includeMascot: include_mascot,
    })
    const token = await getAccessToken()

    let image: { data: string; mimeType: string }
    let modelUsed: string

    if (variant === "imagen-ultra") {
      image = await generateWithImagenUltra(token, fullPrompt, aspect_ratio)
      modelUsed = IMAGEN_ULTRA_MODEL
    } else {
      const geminiModel = variant === "pro-image" ? PRO_IMAGE_MODEL : NANO_MODEL
      const ref = reference_image_base64
        ? { data: reference_image_base64, mimeType: reference_mime_type ?? "image/png" }
        : undefined
      image = await generateWithGeminiImage(geminiModel, token, fullPrompt, aspect_ratio, ref)
      modelUsed = geminiModel
      // Transparent flag means: model paints magenta background (per
      // TRANSPARENT_BG_DIRECTIVE), then generate.sh chroma-keys it to alpha
      // locally. Edge fn returns the raw magenta-backdrop PNG.
    }

    return new Response(
      JSON.stringify({
        image_base64: image.data,
        mime_type: image.mimeType,
        model: modelUsed,
        prompt_sent: fullPrompt,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  }
})
