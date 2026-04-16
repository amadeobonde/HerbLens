// Vertex AI auth + URL helpers for Gemini / Nano Banana / Veo 3.
//
// Required Supabase secrets:
//   GCP_SA_KEY      — full JSON of the service account key (stringified)
//   GCP_PROJECT_ID  — optional, defaults to service account's project_id
//   GCP_LOCATION    — optional, defaults to us-central1

interface ServiceAccount {
  client_email: string
  private_key: string
  project_id: string
}

let cachedToken: { token: string; expiresAt: number } | null = null

function getServiceAccount(): ServiceAccount {
  const raw = Deno.env.get("GCP_SA_KEY")
  if (!raw) throw new Error("GCP_SA_KEY not configured")
  return JSON.parse(raw)
}

export function getProjectId(): string {
  return Deno.env.get("GCP_PROJECT_ID") || getServiceAccount().project_id
}

export function getLocation(): string {
  return Deno.env.get("GCP_LOCATION") || "us-central1"
}

export function vertexUrl(model: string, method: string, locationOverride?: string): string {
  const project = getProjectId()
  const location = locationOverride ?? getLocation()
  // The "global" endpoint is aiplatform.googleapis.com (no region prefix).
  const host = location === "global"
    ? "aiplatform.googleapis.com"
    : `${location}-aiplatform.googleapis.com`
  return `https://${host}/v1/projects/${project}/locations/${location}/publishers/google/models/${model}:${method}`
}

function b64url(input: string | Uint8Array): string {
  const str = typeof input === "string"
    ? btoa(input)
    : btoa(String.fromCharCode(...input))
  return str.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")
}

async function signJwt(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const header = { alg: "RS256", typ: "JWT" }
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/cloud-platform",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }
  const headerB64 = b64url(JSON.stringify(header))
  const payloadB64 = b64url(JSON.stringify(payload))
  const unsigned = `${headerB64}.${payloadB64}`

  const pem = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "")
  const keyData = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0))
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  )
  const sig = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      key,
      new TextEncoder().encode(unsigned),
    ),
  )
  return `${unsigned}.${b64url(sig)}`
}

export async function getAccessToken(): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 60_000) {
    return cachedToken.token
  }
  const sa = getServiceAccount()
  const jwt = await signJwt(sa)
  const resp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  })
  if (!resp.ok) {
    throw new Error(`Token exchange failed: ${resp.status} ${await resp.text()}`)
  }
  const { access_token, expires_in } = await resp.json()
  cachedToken = {
    token: access_token,
    expiresAt: Date.now() + (expires_in * 1000),
  }
  return access_token
}

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}
