import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
const NANOBANANA_API_KEY = Deno.env.get("NANOBANANA_API_KEY")!

serve(async (req) => {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
  
  // 1. Fetch up to 5 featured plants that do NOT have a generated image yet.
  // We identify them by checking if imageUrl is null or missing.
  const { data: plants, error } = await supabase
    .from('plants')
    .select('id, common_name, suggested_prompts')
    .eq('featured', true)
    .is('image_url', null)
    .limit(5)
    
  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
  
  if (!plants || plants.length === 0) {
    return new Response(JSON.stringify({ message: "No featured plants need images today." }), { status: 200 })
  }
  
  const results = []
  
  // 2. Iterate and generate images for each
  for (const plant of plants) {
    const prompt = plant.suggested_prompts?.[0] || `A highly detailed botanical illustration of a ${plant.common_name} plant on a bone background.`
    
    try {
      const response = await fetch("https://api.nanobanana.com/v1/generate", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${NANOBANANA_API_KEY}`
        },
        body: JSON.stringify({
          prompt: prompt,
          style: "botanical_illustration_clean",
          resolution: "1024x1024"
        })
      })
      
      const resData = await response.json()
      
      if (resData.image_url) {
        // 3. Update the plant record in Supabase
        await supabase
          .from('plants')
          .update({ image_url: resData.image_url })
          .eq('id', plant.id)
          
        results.push({ id: plant.id, status: 'success' })
      } else {
        results.push({ id: plant.id, status: 'failed_generation' })
      }
    } catch (e) {
      results.push({ id: plant.id, status: 'error', message: e.message })
    }
  }

  return new Response(JSON.stringify({ message: "Cron complete", results }), { status: 200 })
})
