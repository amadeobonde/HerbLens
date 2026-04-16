// Veo 3.1 video generation (dev-time only) on Vertex AI.
//
// Two model variants:
//   - veo-3.1-generate-preview       → hero/editorial (onboarding intro)
//   - veo-3.1-fast-generate-preview  → celebrations, loading loops (~45% cheaper)
//
// Three endpoints on this one function:
//   POST /generate-video                     → start generation
//     body: { prompt, variant?, aspect_ratio?, duration_seconds?, resolution?, seed?,
//             reference_image_base64?, reference_mime_type? }
//     → { operation_name, status: "running" }
//
//   POST /generate-video?poll=1              → check status
//     body: { operation_name }
//     → { status: "running" } OR { status: "done", video_base64, mime_type } OR { status: "error", error }

import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { getAccessToken, vertexUrl, corsHeaders } from "../_shared/vertex.ts"
import { BAMBOO_CHARACTER_SHEET, BRAND_STYLE, NEGATIVE_PROMPT } from "../_shared/brand.ts"

// Veo 3.1 is allowlist-gated on Vertex. Use Veo 3.0 GA until our project
// is granted preview access. Same audio-generation capability, same pricing.
const MODEL_STANDARD = "veo-3.0-generate-001"
const MODEL_FAST = "veo-3.0-fast-generate-001"

function buildPrompt(
  userPrompt: string,
  opts: { applyBrand: boolean; includeMascot: boolean },
): string {
  if (!opts.applyBrand) return userPrompt
  const sections = [
    userPrompt,
    "",
    "--- STYLE GUIDE (mandatory) ---",
    BRAND_STYLE,
  ]
  if (opts.includeMascot) {
    sections.push("", "--- MASCOT CHARACTER SHEET (mandatory consistency) ---", BAMBOO_CHARACTER_SHEET)
  }
  sections.push("", "--- NEGATIVE (must NOT appear) ---", NEGATIVE_PROMPT)
  return sections.join("\n")
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    // Dev-time video gen — JWT verification is handled by the edge runtime.

    const token = await getAccessToken()
    const url = new URL(req.url)
    const isPoll = url.searchParams.get("poll") === "1"

    if (isPoll) {
      const { operation_name, variant = "standard" } = await req.json()
      if (!operation_name) {
        return new Response(
          JSON.stringify({ error: "operation_name is required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        )
      }
      const model = variant === "fast" ? MODEL_FAST : MODEL_STANDARD
      const pollEndpoint = vertexUrl(model, "fetchPredictOperation")
      const poll = await fetch(pollEndpoint, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ operationName: operation_name }),
      })
      if (!poll.ok) {
        throw new Error(`Veo poll error ${poll.status}: ${await poll.text()}`)
      }
      const op = await poll.json()
      const done = Boolean(op.done)

      if (!done) {
        return new Response(
          JSON.stringify({ status: "running" }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } },
        )
      }

      if (op.error) {
        return new Response(
          JSON.stringify({ status: "error", error: op.error }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } },
        )
      }

      const videos = op.response?.videos ?? op.response?.generatedSamples ?? []
      const video = videos[0] ?? null
      const videoBase64 = video?.bytesBase64Encoded ?? null
      const videoUri = video?.gcsUri ?? null

      return new Response(
        JSON.stringify({
          status: "done",
          video_base64: videoBase64,
          video_gcs_uri: videoUri,
          mime_type: "video/mp4",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const {
      prompt,
      variant = "standard",
      aspect_ratio = "9:16",
      duration_seconds = 6,
      resolution = "720p",
      seed,
      reference_image_base64,
      reference_mime_type,
      apply_brand_style = true,
      include_mascot = false,
    } = await req.json()

    if (!prompt || typeof prompt !== "string") {
      return new Response(
        JSON.stringify({ error: "prompt is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    // Veo 3.1 constraint: 1080p and 4k require 8s duration.
    const finalDuration = (resolution === "1080p" || resolution === "4k") ? 8 : duration_seconds

    const model = variant === "fast" ? MODEL_FAST : MODEL_STANDARD
    const endpoint = vertexUrl(model, "predictLongRunning")

    const instance: Record<string, unknown> = {
      prompt: buildPrompt(prompt, { applyBrand: apply_brand_style, includeMascot: include_mascot }),
    }
    if (reference_image_base64) {
      instance.image = {
        bytesBase64Encoded: reference_image_base64,
        mimeType: reference_mime_type ?? "image/png",
      }
    }

    const parameters: Record<string, unknown> = {
      aspectRatio: aspect_ratio,
      durationSeconds: finalDuration,
      resolution,
      personGeneration: "allow_adult",
      sampleCount: 1,
    }
    if (seed !== undefined) parameters.seed = seed

    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        instances: [instance],
        parameters,
      }),
    })

    if (!response.ok) {
      throw new Error(`Veo error ${response.status}: ${await response.text()}`)
    }

    const op = await response.json()
    return new Response(
      JSON.stringify({
        operation_name: op.name,
        status: "running",
        model,
        resolution,
        duration_seconds: finalDuration,
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
