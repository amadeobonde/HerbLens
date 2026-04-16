import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "jsr:@supabase/supabase-js@2"
import { getAccessToken, vertexUrl, corsHeaders } from "../_shared/vertex.ts"

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

    const { messages, context_plant_id, stream } = await req.json()
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

    const systemInstruction = `You are Bamboo, a friendly and knowledgeable herbal medicine expert panda. You help users learn about herbs, teas, tinctures, and natural remedies. Warn about contraindications and drug interactions. Be warm but scientifically accurate. Prefer plain, encouraging language over jargon.${plantContext}${healthContext}`

    const contents = messages.map((m: any) => ({
      role: m.role === "assistant" ? "model" : "user",
      parts: [{ text: typeof m.content === "string" ? m.content : JSON.stringify(m.content) }],
    }))

    const token = await getAccessToken()
    const shouldStream = stream !== false
    const method = shouldStream ? "streamGenerateContent" : "generateContent"
    const suffix = shouldStream ? "?alt=sse" : ""
    const endpoint = vertexUrl("gemini-2.5-flash", method) + suffix

    const upstream = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        systemInstruction: { role: "user", parts: [{ text: systemInstruction }] },
        contents,
        generationConfig: { temperature: 0.7 },
      }),
    })

    if (!upstream.ok) {
      const errText = await upstream.text()
      throw new Error(`Vertex error ${upstream.status}: ${errText}`)
    }

    if (!shouldStream) {
      const result = await upstream.json()
      const text = result.candidates?.[0]?.content?.parts?.map((p: any) => p.text).join("") ?? ""
      return new Response(
        JSON.stringify({ message: text }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const { readable, writable } = new TransformStream()
    const writer = writable.getWriter()
    const encoder = new TextEncoder()
    const decoder = new TextDecoder()

    ;(async () => {
      const reader = upstream.body!.getReader()
      let buffer = ""
      try {
        while (true) {
          const { done, value } = await reader.read()
          if (done) break
          buffer += decoder.decode(value, { stream: true })
          const lines = buffer.split("\n")
          buffer = lines.pop() ?? ""
          for (const line of lines) {
            if (!line.startsWith("data:")) continue
            const payload = line.slice(5).trim()
            if (!payload) continue
            try {
              const json = JSON.parse(payload)
              const delta = json.candidates?.[0]?.content?.parts?.map((p: any) => p.text).join("") ?? ""
              if (delta) {
                await writer.write(encoder.encode(`data: ${JSON.stringify({ delta })}\n\n`))
              }
            } catch (_) { /* skip malformed */ }
          }
        }
        await writer.write(encoder.encode(`data: [DONE]\n\n`))
      } finally {
        await writer.close()
      }
    })()

    return new Response(readable, {
      headers: {
        ...corsHeaders,
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
      },
    })
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  }
})
