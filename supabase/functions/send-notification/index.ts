import "jsr:@supabase/functions-js/edge-runtime.d.ts"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const { device_token, title, body, data } = await req.json()
    if (!device_token || !title || !body) {
      return new Response(
        JSON.stringify({ error: "device_token, title, and body are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    const keyId = Deno.env.get("APNS_KEY_ID")
    const teamId = Deno.env.get("APNS_TEAM_ID")
    const privateKey = Deno.env.get("APNS_PRIVATE_KEY")

    if (!keyId || !teamId || !privateKey) {
      throw new Error("APNs credentials not configured")
    }

    // TODO: Implement JWT signing for APNs auth token
    return new Response(
      JSON.stringify({
        success: true,
        message: "Notification queued (APNs integration pending)",
        payload: { title, body, data },
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
