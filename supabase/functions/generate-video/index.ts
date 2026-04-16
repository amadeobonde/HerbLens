// Veo 3 — Google's video generation model (veo-3.0-generate-001).
// Use for short animated clips: onboarding hero, scan celebration, loading loops.
//
// Two endpoints:
//   POST /generate-video           → { prompt, aspect_ratio?, duration_seconds? } → { operation_name }
//   POST /generate-video?poll=1    → { operation_name }                          → { status, video_url? }
//
// Veo is async: kick off a generation, poll until done, then fetch the video URL.

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

    const geminiKey = Deno.env.get("GEMINI_API_KEY")
    if (!geminiKey) throw new Error("GEMINI_API_KEY not configured")

    const url = new URL(req.url)
    const isPoll = url.searchParams.get("poll") === "1"

    if (isPoll) {
      const { operation_name } = await req.json()
      if (!operation_name) {
        return new Response(
          JSON.stringify({ error: "operation_name is required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        )
      }
      const pollEndpoint = `https://generativelanguage.googleapis.com/v1beta/${operation_name}?key=${geminiKey}`
      const poll = await fetch(pollEndpoint)
      if (!poll.ok) {
        const errText = await poll.text()
        throw new Error(`Veo poll error ${poll.status}: ${errText}`)
      }
      const op = await poll.json()
      const done = Boolean(op.done)
      const videos = op.response?.generateVideoResponse?.generatedSamples
        ?? op.response?.generatedVideos
        ?? []
      const videoUri = videos[0]?.video?.uri ?? videos[0]?.videoUri ?? null
      return new Response(
        JSON.stringify({
          status: done ? "done" : "running",
          video_url: videoUri ? `${videoUri}&key=${geminiKey}` : null,
          error: op.error ?? null,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const { prompt, aspect_ratio, duration_seconds } = await req.json()
    if (!prompt || typeof prompt !== "string") {
      return new Response(
        JSON.stringify({ error: "prompt is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/veo-3.0-generate-001:predictLongRunning?key=${geminiKey}`

    const response = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        instances: [{ prompt }],
        parameters: {
          aspectRatio: aspect_ratio ?? "9:16",
          durationSeconds: duration_seconds ?? 6,
          personGeneration: "allow_adult",
          sampleCount: 1,
        },
      }),
    })

    if (!response.ok) {
      const errText = await response.text()
      throw new Error(`Veo error ${response.status}: ${errText}`)
    }

    const op = await response.json()
    return new Response(
      JSON.stringify({ operation_name: op.name, status: "running" }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  }
})
