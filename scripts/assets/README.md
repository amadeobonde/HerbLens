# HerbLens asset generation pipeline

Dev-time tool. Generates brand assets (mascot PNGs, scene illustrations,
videos) via the Supabase edge functions (`generate-image`, `generate-video`).
**Not shipped in the iOS app.**

## Workflow

1. Pick a prompt file in `prompts/` (or write a new one)
2. Run `./generate.sh <prompt-name>` — e.g. `./generate.sh bamboo-default`
3. Output lands in `out/<prompt-name>.png` (or `.mp4` for videos)
4. Have Claude review it: paste the `out/` path in chat. Claude reads the
   file, scores it against the brand rubric, and either accepts or rewrites
   the prompt for another try.
5. On accept: move the file into `HerbLens/Assets.xcassets/` with the right
   imageset folder.

## Files

- `prompts/*.json` — one file per asset. Fields: `prompt`, `variant`,
  `transparent`, `aspect_ratio`, `duration_seconds`, `resolution` (for videos)
- `generate.sh` — wrapper that posts a prompt JSON to the appropriate edge
  function and saves the result
- `out/` — gitignored; staging area for generated assets awaiting review

## Strict review rubric (Claude applies before accepting)

1. **Brand fidelity** — palette, painterly style, no AI-art tells (no lens
   flares, cyan rim light, random particles, watermarks)
2. **Mascot consistency** — Bamboo looks the same across every asset (round,
   chibi, soft off-white fur, charcoal markings, gentle smile)
3. **Background compliance**
   - `transparent: true` → actual alpha channel, not just white pixels
   - `transparent: false` → clean themed backdrop (bone + sage vignette),
     nothing else
4. **Technical quality** — no malformed hands, asymmetric eyes, fused limbs,
   jpeg artifacts
5. **Safe area** — subject has 10–15% margin, no critical detail within 8%
   of any edge

**Default verdict is REJECT.** I only accept a shippable asset.

## Reviewing a PNG's alpha channel

The 2-pass transparent mode (see `generate-image/index.ts`) runs a second
Nano Banana call to strip the background to alpha. If the result still has
a visible backdrop, regenerate with a more aggressive directive.

Quick CLI sanity check:
```bash
python3 -c "from PIL import Image; i=Image.open('out/bamboo-default.png'); print(i.mode, 'transparent pixels:', sum(1 for p in i.getdata() if len(p)==4 and p[3]==0))"
```
