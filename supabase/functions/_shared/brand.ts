// HerbLens canonical brand style guide.
// Used by generate-image / generate-video edge functions and Claude's asset
// review workflow. If we update the mascot or palette, edit ONLY this file
// and redeploy all image/video functions.

export const BAMBOO_CHARACTER_SHEET = `
CHARACTER: "Bamboo", the HerbLens mascot.
SPECIES: Small round panda cub, stylized like a premium app mascot.
BUILD: Rotund, chibi-proportioned (head ~1/2 body height), short stubby limbs.
FACE: Big glossy black eyes each with ONE crisp white highlight (same size,
same position on both eyes — strictly symmetric). Small pink blush circles
on cheeks (solid, clean-edged, not smudged). Gentle closed-mouth smile,
lightly curved, never toothy. Small round ears tipped with a tiny bamboo
leaf detail behind each ear (leaf visible on both sides when the pose
allows it).
FUR: Classic panda palette — warm off-white body #F7EFE2 (not pure white),
clean charcoal eye patches, ears, arms, and legs #2A2A2A (never pure
black). Silhouette is CLEAN and CONFIDENT — smooth curves, no fuzzy/wispy
fur edges, no visible brushstrokes. Fur surface is flat-to-softly-shaded,
NOT painterly or textured.
EXPRESSION: Always calm, curious, or quietly joyful. Never scared,
aggressive, or stylized-cool.
POSE STYLE: Grounded weight, relaxed posture, slight forward lean.
SIGNATURE PROPS: Small steaming teacup (ceramic, earthy glaze), sprig of
herbs, small botanical scroll. Never modern tech props.
`.trim()

export const BRAND_STYLE = `
AESTHETIC: Clean modern mascot illustration — think premium app-icon
polish (Headspace, Duolingo, Calm) meets a warm botanical brand. The style
is SMOOTH, CLEAN, and REPRODUCIBLE — designed so the same character can be
drawn in many poses without the look drifting. NOT painterly, NOT
watercolor, NOT gouache, NOT sketchy.

SURFACE TREATMENT:
- Flat base colors with gentle soft-shaded volume (2 to 3 shade steps max).
- Shading is smooth airbrushed falloff, not brushstrokes — like a digital
  vector illustration with subtle gradients baked in.
- NO visible paper grain, NO canvas texture, NO brush marks, NO paint
  streaks, NO watercolor bleeds, NO ink splatter.
- Silhouettes read as clean confident shapes at thumbnail size.
- A subtle darker-edge contour (soft ambient occlusion, 1-2px equivalent)
  may be used for depth — but no hard black outline around the whole form.

PALETTE (strict, do not invent new hues):
- Sage #7B9467 (primary botanical accent)
- Forest #3F5E4A (darkest shade, for depth)
- Bone #F7EFE2 (background fill + mascot body base)
- Amber #C9872A (highlights, tea, warmth)
- Ember #C0522F (warnings only, rarely used)
- Charcoal #2A2A2A (mascot markings, darkest shadows)

LIGHTING: Warm, diffuse, single-source from upper left. Highlights on
upper curves, gentle core shadow on lower curves, soft ambient fill. No
harsh specular hotspots. No rim-light or neon edge-light.

COMPOSITION: Subject centered with generous padding (10-15% margin on all
sides for safe area). Subject must read clearly at 64x64 thumbnail size.

FORBIDDEN (reject on sight):
- Painterly / gouache / watercolor / sketchy / drawn look — we want CLEAN
- Visible brushstrokes, paint texture, paper grain, canvas fiber
- Photorealism, 3D rendering, plasticky shading
- Hard black vector outlines around the whole form
- Pure white (#FFFFFF) or pure black (#000000) — use Bone/Charcoal
- Stock-AI-art tells: lens flares, random floating particles, cyan rim light
- Text / typography in the image
- Watermarks, signatures, UI chrome, checkerboard patterns
- Manic or creepy expressions on Bamboo
- Modern tech (phones, laptops, plastic bottles)
- Clothing on Bamboo (no hats, glasses, scarves, shirts, aprons)
- Asymmetric eyes (eyes must be IDENTICAL size, shape, highlight placement)
- Extra limbs, fused fingers, melted features
`.trim()

export const NEGATIVE_PROMPT = [
  "photoreal", "3D render", "CGI", "plastic",
  "harsh outlines", "vector art", "flat shading",
  "watermark", "signature", "text", "typography", "logo",
  "lens flare", "bloom", "particles",
  "creepy", "scary", "distorted face",
  "extra limbs", "extra fingers", "fused fingers", "asymmetric eyes",
  "low quality", "blurry", "jpeg artifacts",
].join(", ")

// Appended to prompts when transparent backgrounds are required.
// Gemini image models on Vertex CANNOT emit real alpha-PNG — they output
// RGB only. So we chroma-key: have the model paint a pure magenta
// (#FF00FF) backdrop, then the local pipeline (generate.sh) strips those
// pixels to alpha in a post-process step. #FF00FF is chosen because it's
// vanishingly unlikely to appear in a botanical illustration.
export const TRANSPARENT_BG_DIRECTIVE = `
OUTPUT BACKGROUND (critical, follow exactly):
The background behind the subject MUST be a single, perfectly flat, solid
pure MAGENTA color, RGB (255, 0, 255), also written as hex #FF00FF.
- Every pixel that is not the subject should be this exact magenta.
- NO gradient, NO noise, NO texture, NO shadow under the subject.
- NO ground plane, NO environment, NO props behind the subject.
- NO checkerboard pattern (do not depict transparency visually — fill with
  solid magenta instead).
- Do NOT use any other color for background. Not white, not cream, not
  sage, not gray — ONLY #FF00FF magenta.
This magenta will be replaced with true alpha-channel transparency in a
post-processing step, so the result must be a clean silhouette against
solid magenta.
`.trim()

// Appended when we want a themed solid backdrop instead of transparent.
export const THEMED_BG_DIRECTIVE = `
BACKGROUND: Soft #F7EFE2 (bone) fill with a subtle radial vignette in
#7B9467 (sage) at the edges. No objects in the background. No texture
overlay. The subject should sit centered with breathing room.
`.trim()
