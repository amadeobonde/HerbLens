#!/usr/bin/env bash
# HerbLens dev-time asset generator.
#
# Usage:
#   ./generate.sh <prompt-name>
#
# Where <prompt-name> matches a file in prompts/<prompt-name>.json
# (without the .json extension).
#
# Requires:
#   - HerbLens/Config/Debug.xcconfig with SUPABASE_ANON_KEY
#   - Edge functions deployed to project flrfeymfuuxycfwlmlgy
#   - jq, curl, python3

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <prompt-name>" >&2
  echo "  prompts available:" >&2
  ls "$(dirname "$0")/prompts" | sed 's/\.json$//' | sed 's/^/    /' >&2
  exit 1
fi

NAME="$1"
ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$ROOT/../.." && pwd)"
PROMPT_FILE="$ROOT/prompts/$NAME.json"
OUT_DIR="$ROOT/out"

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "error: no prompt file $PROMPT_FILE" >&2
  exit 1
fi

ANON_KEY=$(grep SUPABASE_ANON_KEY "$REPO_ROOT/HerbLens/Config/Debug.xcconfig" | cut -d'=' -f2 | xargs)
if [[ -z "$ANON_KEY" ]]; then
  echo "error: SUPABASE_ANON_KEY not found in Debug.xcconfig" >&2
  exit 1
fi

BASE_URL="https://flrfeymfuuxycfwlmlgy.supabase.co/functions/v1"
MEDIA=$(jq -r '.media' "$PROMPT_FILE")

mkdir -p "$OUT_DIR"

if [[ "$MEDIA" == "image" ]]; then
  OUT="$OUT_DIR/$NAME.png"
  echo "→ $NAME (image) — generating via $BASE_URL/generate-image"
  # Strip .media + .use_bamboo_reference (shell-only flags).
  PAYLOAD=$(jq 'del(.media) | del(.use_bamboo_reference)' "$PROMPT_FILE")

  # If the prompt requests the canonical Bamboo reference, auto-inject
  # bamboo-default.png as the reference_image_base64 for character lock.
  USE_REF=$(jq -r '.use_bamboo_reference // false' "$PROMPT_FILE")
  # Prefer the locked canonical reference; fall back to last bamboo-default output
  REF_PATH="$ROOT/reference/bamboo-canonical.png"
  [[ -f "$REF_PATH" ]] || REF_PATH="$OUT_DIR/bamboo-default.png"
  if [[ "$USE_REF" == "true" && -f "$REF_PATH" ]]; then
    echo "  (injecting $(basename "$REF_PATH") as character reference)"
    REF_B64_FILE=$(mktemp)
    trap 'rm -f "$REF_B64_FILE"' EXIT
    base64 -i "$REF_PATH" | tr -d '\n' > "$REF_B64_FILE"
    PAYLOAD=$(echo "$PAYLOAD" | jq --rawfile ref "$REF_B64_FILE" \
      '. + {reference_image_base64: $ref, reference_mime_type: "image/png"}')
  elif [[ "$USE_REF" == "true" ]]; then
    echo "  WARNING: use_bamboo_reference=true but no reference found — generate bamboo-default first" >&2
  fi

  PAYLOAD_FILE=$(mktemp)
  trap 'rm -f "$PAYLOAD_FILE" "${REF_B64_FILE:-}"' EXIT
  printf '%s' "$PAYLOAD" > "$PAYLOAD_FILE"

  RESPONSE=$(curl -sS -X POST "$BASE_URL/generate-image" \
    -H "Authorization: Bearer $ANON_KEY" \
    -H "Content-Type: application/json" \
    --data "@$PAYLOAD_FILE")

  if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    echo "error: $(echo "$RESPONSE" | jq -r '.error')" >&2
    exit 1
  fi

  echo "$RESPONSE" | jq -r '.image_base64' | base64 -d > "$OUT"
  MODEL=$(echo "$RESPONSE" | jq -r '.model')
  SIZE=$(ls -la "$OUT" | awk '{print $5}')
  echo "✓ saved $OUT ($SIZE bytes, model: $MODEL)"

  # If transparent was requested, the model painted a magenta backdrop.
  # Chroma-key it to true alpha in-place.
  TRANSPARENT=$(jq -r '.transparent // false' "$PROMPT_FILE")
  if [[ "$TRANSPARENT" == "true" ]]; then
    python3 - "$OUT" <<'PY'
import sys
from PIL import Image

path = sys.argv[1]
img = Image.open(path).convert("RGBA")
w, h = img.size
pixels = img.load()

# Chroma-key that distinguishes magenta (R≈B, low G) from blush pink
# (R >> B). Magenta: r and b are close to each other; blush: r is much
# greater than b. We key on |R - B| being SMALL AND both R & B being
# high AND G being much lower.
stripped = 0
edge_soft = 0
for y in range(h):
    for x in range(w):
        r, g, b, _a = pixels[x, y]
        rb_diff = abs(r - b)
        rb_min = min(r, b)
        g_gap = rb_min - g  # how much lower G is than the lower of R/B

        # Hard magenta: r ≈ b, both high, g much lower
        if rb_diff < 25 and rb_min > 170 and g_gap > 100:
            pixels[x, y] = (0, 0, 0, 0)
            stripped += 1
        # Soft magenta fringe: same shape but looser thresholds. Still
        # requires R ≈ B (which blush never satisfies — blush has R-B ≈ 70+).
        elif rb_diff < 35 and rb_min > 130 and g_gap > 60:
            # Neutralize the magenta tint: drag R and B toward G
            neutral = (r + b + g) // 3
            # Partial alpha proportional to how magenta-like the pixel is
            alpha = max(0, 255 - (g_gap * 2))
            pixels[x, y] = (neutral, g, neutral, alpha)
            edge_soft += 1

img.save(path, "PNG")
total = w * h
pct = 100 * stripped / total
print(f"  chroma-key: {pct:.1f}% stripped to alpha, {edge_soft} soft-edge pixels refined ({w}x{h})")
if pct < 10:
    print("  WARNING: very little magenta detected — model may have ignored the directive")
PY
  fi

elif [[ "$MEDIA" == "video" ]]; then
  OUT="$OUT_DIR/$NAME.mp4"
  echo "→ $NAME (video) — kicking off Veo via $BASE_URL/generate-video"
  PAYLOAD=$(jq 'del(.media) | del(.use_bamboo_reference)' "$PROMPT_FILE")
  VARIANT=$(jq -r '.variant // "standard"' "$PROMPT_FILE")

  # Inject canonical Bamboo as the starting frame for character + style lock.
  # Veo 3.0 supports image-to-video; the first frame anchors the whole clip.
  USE_REF=$(jq -r '.use_bamboo_reference // false' "$PROMPT_FILE")
  REF_PATH="$ROOT/reference/bamboo-canonical.png"
  if [[ "$USE_REF" == "true" && -f "$REF_PATH" ]]; then
    echo "  (injecting bamboo-canonical.png as opening frame for style lock)"
    REF_B64_FILE=$(mktemp)
    trap 'rm -f "$REF_B64_FILE" "${PAYLOAD_FILE:-}"' EXIT
    base64 -i "$REF_PATH" | tr -d '\n' > "$REF_B64_FILE"
    PAYLOAD=$(echo "$PAYLOAD" | jq --rawfile ref "$REF_B64_FILE" \
      '. + {reference_image_base64: $ref, reference_mime_type: "image/png"}')
  fi

  PAYLOAD_FILE=$(mktemp)
  trap 'rm -f "$PAYLOAD_FILE" "${REF_B64_FILE:-}"' EXIT
  printf '%s' "$PAYLOAD" > "$PAYLOAD_FILE"
  START=$(curl -sS -X POST "$BASE_URL/generate-video" \
    -H "Authorization: Bearer $ANON_KEY" \
    -H "Content-Type: application/json" \
    --data "@$PAYLOAD_FILE")

  if echo "$START" | jq -e '.error' >/dev/null 2>&1; then
    echo "error: $(echo "$START" | jq -r '.error')" >&2
    exit 1
  fi

  OP_NAME=$(echo "$START" | jq -r '.operation_name')
  echo "  operation: $OP_NAME"
  echo "  polling every 15s (Veo generally takes 1–4 min)..."

  while true; do
    sleep 15
    POLL=$(curl -sS -X POST "$BASE_URL/generate-video?poll=1" \
      -H "Authorization: Bearer $ANON_KEY" \
      -H "Content-Type: application/json" \
      --data "{\"operation_name\":\"$OP_NAME\",\"variant\":\"$VARIANT\"}")

    STATUS=$(echo "$POLL" | jq -r '.status')
    echo "  status: $STATUS"
    if [[ "$STATUS" == "done" ]]; then
      echo "$POLL" | jq -r '.video_base64' | base64 -d > "$OUT"
      SIZE=$(ls -la "$OUT" | awk '{print $5}')
      echo "✓ saved $OUT ($SIZE bytes)"
      break
    elif [[ "$STATUS" == "error" ]]; then
      echo "error: $(echo "$POLL" | jq -c '.error')" >&2
      exit 1
    fi
  done
else
  echo "error: unknown media type '$MEDIA' in $PROMPT_FILE" >&2
  exit 1
fi

echo
echo "Next: paste the output path in Claude for review:"
echo "  $OUT"
