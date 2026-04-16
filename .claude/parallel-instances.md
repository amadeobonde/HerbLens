# HerbLens — Parallel Instance Briefs

10 concurrent Claude Code instances, one per workstream. **Read `CLAUDE.md` first.**

**Before starting your instance:** always run `git pull` and `git checkout -b feat/<your-feature>`.
**When done:** commit to your branch, do NOT merge or push. The user merges.

---

## Current session context (must-know)

### Google Cloud / Vertex AI
- Project: `herblens-dev` (outside corporate org, no blocking policies)
- Service account: `testing@herblens-dev.iam.gserviceaccount.com` with `roles/aiplatform.user`
- Auth: SA JSON → OAuth token via `supabase/functions/_shared/vertex.ts`
- Billing: $300 Google Cloud trial credits on the account

### Model lineup (frozen for this sprint)
| Purpose | Model | Where |
|---|---|---|
| Plant vision + identify | `gemini-3-flash-preview` | `identify-plant` edge fn |
| Chat (Bamboo) | `gemini-3-flash-preview` + dynamic thinking | `ai-chat` edge fn |
| Health score (free tier) | `gemini-3-flash-preview` | `health-score` edge fn |
| Health score (premium tier) | `gemini-3-pro-preview` | `health-score` edge fn (auto-routes on `user_profiles.subscription_tier`) |
| Image gen (dev-time) | `gemini-2.5-flash-image` (nano) / `gemini-3-pro-image-preview` (pro) / `imagen-4.0-ultra-generate-001` (ultra) | `generate-image` edge fn |
| Video gen (dev-time) | `veo-3.0-generate-001` (standard) / `veo-3.0-fast-generate-001` (fast) | `generate-video` edge fn |

All runtime edge functions are already deployed. **iOS never holds API keys** — it calls Supabase edge fns.

### Brand system (single source of truth)
- `supabase/functions/_shared/brand.ts` — `BRAND_STYLE`, `BAMBOO_CHARACTER_SHEET`, `NEGATIVE_PROMPT`, `TRANSPARENT_BG_DIRECTIVE`, `THEMED_BG_DIRECTIVE`
- **Palette:** Sage `#7B9467` · Forest `#3F5E4A` · Bone `#F7EFE2` · Amber `#C9872A` · Ember `#C0522F` · Charcoal `#2A2A2A`
- **Aesthetic:** clean app-mascot illustration (Headspace/Duolingo polish). Flat base colors + smooth airbrushed soft-shading. **NEVER painterly, watercolor, gouache, or sketchy.**

### Locked brand assets (in `scripts/assets/reference/`)
These are APPROVED and must not be regenerated casually.

| Asset | Purpose | Notes |
|---|---|---|
| `bamboo-canonical.png` | Hero mascot / character reference | 2048×2048 RGBA, welcoming pose |
| `bamboo-scanning.png` | Scan screen empty/loading | Magnifying glass + herb sprig |
| `bamboo-celebrating.png` | Scan-complete celebration | V-arm pose + leaf confetti |
| `bamboo-brewing.png` | Recipes header | Stirring teapot + steam |
| `bamboo-teacher.png` | AI Chat avatar (Bamboo) | Seated with botanical scroll |
| `bamboo-sleeping.png` | Empty/idle state | Curled on bamboo mat |
| `scene-apothecary.png` | Paywall hero | Imagen 4 Ultra, 3:4 |
| `tea-card-chamomile.png` | Recipes thumbnail | Chamomile cup flatlay |
| `tea-card-peppermint.png` | Recipes thumbnail | Peppermint mug flatlay |
| `video-brew-hero.mp4` | Onboarding hero | Veo 3, 8s, 9:16, 1080p |

Copy these into `HerbLens/HerbLens/Assets.xcassets/` imagesets as needed for your feature. Do NOT regenerate the canonical set; if you need a new pose/angle, see Asset Generation below.

### Asset generation (any instance, any time)
You may generate NEW assets (more tea cards, tincture stills, additional Bamboo poses, empty states, etc.) using the dev-time pipeline — apply the same strict review we use:

1. `cd scripts/assets`
2. Write a new prompt JSON in `prompts/<your-asset>.json`. Follow the structure of existing files. Set `use_bamboo_reference: true` for any mascot pose to auto-inject `reference/bamboo-canonical.png` for character lock.
3. Run `./generate.sh <your-asset>`. Output lands in `out/<your-asset>.png` or `.mp4`.
4. Review against the rubric below (use the Read tool to view the PNG/MP4). **Default verdict is REJECT.**
5. If rejected, refine the prompt (tightening what the model drifted on) and regen. Max 3 tries; if still not shippable, leave a note in `scripts/assets/out/<asset>.md` and move on.
6. On ACCEPT, move the file to `HerbLens/HerbLens/Assets.xcassets/<Feature>/<Asset>.imageset/` and commit the prompt JSON to your branch.

### Strict asset review rubric
1. **Character lock** — any Bamboo asset must match `reference/bamboo-canonical.png`: chibi proportions, symmetric glossy black eyes with matching white highlights, small pink blush circles, bamboo-leaf ear tips on both sides, fur palette exact.
2. **Style** — clean app-mascot illustration. **Reject on sight:** painterly brushstrokes, paper grain, watercolor bleeds, sketchy edges, pure black outlines.
3. **Transparency** — if `transparent: true`, PNG must be RGBA with >30% genuine alpha (chroma-key pipeline handles this; the script reports stripped pct).
4. **Background** — if `transparent: false`, background must be bone `#F7EFE2` with soft sage vignette OR a specified themed environment. NO magenta leak, NO random props, NO text.
5. **Palette discipline** — only the 6 brand hues. No stock AI-art tells (cyan rim light, lens flares, glitter, stars).
6. **Expression** — Bamboo is always calm/curious/quietly joyful. Never manic, scared, or stylized-cool.
7. **Safe area** — 10-15% margin on every side. Subject reads at thumbnail size.

### Premium "glow effect" expectations
Subscribers (`subscription_tier == "premium"`) get a noticeably elevated experience:
- **AI Chat** (Instance 9) — streaming Bamboo expert chat, unlimited
- **Health scoring with Gemini 3 Pro** — deeper contraindication reasoning per scan
- **Full recipe access** (Instance 7) — all teas, tinctures, full step-by-step
- **Unlimited scans** — free tier is rate-limited (enforce in Instance 5 / Instance 2 service)
- **Scene-apothecary hero on paywall** (Instance 10)
- **Premium visual polish** — Liquid Glass surfaces on HerbProfile (Instance 6), animated mascot transitions, haptics

Every feature-owning instance must distinguish free vs premium visually — not just functionally.

---

## Pending requests to Shared/Services

If you need something from Shared/ or Services/ that doesn't exist, append a line here.
Instance 1 or 2 will pick it up.

- Instance 4 (Home) → Instance 6 (HerbProfile): `HomeView` pushes `HomeRoute.plant(id:)` onto its NavigationStack and currently routes to `PendingPlantDetailDestination` (a stub at `Features/Home/__pending__PlantDetailDestination.swift`). When `HerbProfileView` lands, swap the `.navigationDestination(for: HomeRoute.self)` body in `HomeView` to push the real view and delete the stub file.

---

## Instance 1 — Shared Foundation (Models, Protocols, Theme)

**Skill:** `/swiftui-patterns`
**Owns:** `HerbLens/HerbLens/Shared/**`, `HerbLens/HerbLens/App/**`
**Depends on:** nothing — run first
**Deliverables:**
- All Codable models from `herblens_data_structure.json` in `Shared/Models/`
- All service protocols listed in CLAUDE.md §5.2 in `Shared/Protocols/`
- `Shared/Theme/` — the 6-color palette, typography (SF Pro + custom display face), spacing scale (4/8/12/16/24/32), Liquid Glass tokens per iOS 26
- `Shared/Extensions/` — `Color+Hex`, `Date+Relative`, `View+Conditional`
- `App/AppDependencies.swift` — DI container with live + mock factories
- `App/HerbLensApp.swift` — inject dependencies via `@Environment`
- Unit tests: round-trip JSON decode of the sample plant entry from `herblens_data_structure.json`

**Acceptance:**
- Every other instance can import from `Shared/` without stubbing
- Theme tokens match the brand palette EXACTLY (copy hex values from `supabase/functions/_shared/brand.ts` line 40-45)
- `AppDependencies.mock` works in `#Preview` blocks

---

## Instance 2 — Services (Live + Mock)

**Skill:** `/swift-protocol-di-testing`
**Owns:** `HerbLens/HerbLens/Services/**`
**Depends on:** Instance 1 protocols/models (stub locally if not ready)
**Deliverables:**
- `Services/Live/SupabaseClientProvider.swift` — singleton client from `AppConfig`
- `Services/Live/SupabaseAuthService.swift` → conforms to `AuthService`
- `Services/Live/SupabasePlantsRepository.swift` → conforms to `PlantsRepository`
- `Services/Live/SupabaseScansRepository.swift` → calls `identify-plant` edge fn, saves to `scans` table
  - Include free-tier rate limiting: track scan count per user per day; block if over limit (3/day, configurable)
- `Services/Live/SupabaseChatRepository.swift` → streams from `ai-chat` edge fn (SSE, `data: {"delta":"..."}\n\n`)
- `Services/Live/SupabaseHealthProfileRepository.swift`
- `Services/Live/RevenueCatSubscriptionService.swift` → conforms to `SubscriptionService`
- `Services/Mock/Mock*.swift` — in-memory versions returning fixture data (include at least 5 realistic plants: chamomile, peppermint, ginger, lavender, echinacea)
- Tests: each live service exercised against mock responses

**Acceptance:**
- All edge-function endpoints correctly target `https://flrfeymfuuxycfwlmlgy.supabase.co/functions/v1/*`
- Auth header uses Supabase session JWT, not the anon key
- Mock services power Xcode Previews for every feature

---

## Instance 3 — Onboarding + Auth

**Skill:** `/swiftui-patterns`
**Owns:** `HerbLens/HerbLens/Features/Onboarding/**`
**Depends on:** `AuthService`, `HealthProfileRepository`, `UserProfile`, `HealthProfile`, `HealthGoal`
**Deliverables:**
- Welcome screen with "Scan. Learn. Brew." tagline
  - **Hero video:** play `Resources/video-brew-hero.mp4` (already produced — do NOT regenerate at runtime) on loop with `AVPlayer`, muted, autoplay
  - Fallback to `bamboo-canonical.png` static while video buffers
- Sign-up / Sign-in (email + magic link) using `AuthService`
- Multi-step health profile wizard:
  1. Primary health goals (Sleep, Digestive, Stress, Immunity, Skin, Pain, Energy, Focus) — ranked drag-to-order
  2. Allergies (tag input with common presets)
  3. Medications (tag input)
  4. Conditions (pregnant, breastfeeding, high blood pressure, diabetes, etc.)
  5. Experience level (beginner/intermediate/advanced)
- On finish → set `user_profiles.onboarding_completed = true`

**Asset freedom:** If you need a specific transition illustration (e.g. Bamboo handing a welcome card), generate via `scripts/assets/` using a new prompt + our rubric.

**Tests:** state transitions, happy-path sign-up, magic-link flow

---

## Instance 4 — Home / Explore

**Skill:** `/swiftui-patterns`
**Owns:** `HerbLens/HerbLens/Features/Home/**`
**Depends on:** `PlantsRepository`, `Plant`, `HighlightCollection`
**Deliverables:**
- Home feed with:
  - Big scan CTA button at top — Bamboo peeks from the button edge using `bamboo-canonical.png`
  - Featured plants carousel
  - Highlight collections sections (Sleep Aids, Digestive Support, etc.)
    - Collection cover art: use pre-generated PNGs from `Assets.xcassets/Collections/` if present, else generate via `scripts/assets/` with `variant: "imagen-ultra"` and commit the result
  - "Recently scanned" quick-access row (from Vault)
- Pull-to-refresh
- Tap plant → push to HerbProfile feature via `NavigationStack` path binding

**Asset freedom:** Generate collection covers (8-12 needed) via the asset pipeline. Prompt template at `scripts/assets/prompts/scene-apothecary.json` is a good starting point — adapt per collection theme.

**Tests:** renders with mock repository data (at least 2 collections)

---

## Instance 5 — Scan (Camera + Gemini Identify)

**Skill:** `/swiftui-patterns`
**Owns:** `HerbLens/HerbLens/Features/Scan/**`
**Depends on:** `ScansRepository`, `PlantsRepository`, `SubscriptionService`
**AI stack:** `identify-plant` edge fn wraps Gemini 3 Flash vision. Returns `{ plant_name, confidence, scientific_name, properties[], description, candidates[] }` as structured JSON.

**Deliverables:**
- Camera capture (AVFoundation) + PhotosPicker fallback
- Downscale + JPEG-compress to ≤1024px on-device before upload (save tokens)
- Loading state: show `bamboo-scanning.png` + subtle pulse animation while the edge fn runs
- Result card with confidence score, plant name, primary image
- CTA: "Save to Vault" / "Scan another"
- Low-confidence flow (confidence < 0.75): show `candidates[]` as tappable chips so user picks
- Success animation: show `bamboo-celebrating.png` with a spring-in transition + haptic on successful identify
- Free-tier quota UX: show remaining scans for today; gate with paywall when exhausted (use `SubscriptionService.currentTier()`)

**Asset freedom:** Generate additional Bamboo poses (e.g. "Bamboo holding a magnifying glass at a different angle") if your UX needs them.

**Tests:** mock `ScansRepository` returning fixture identify results covering high-conf and low-conf paths

---

## Instance 6 — Herb Profile (Plant detail, Liquid Glass)

**Skill:** `/liquid-glass-design`
**Owns:** `HerbLens/HerbLens/Features/HerbProfile/**`
**Depends on:** `PlantsRepository`, `Plant`, `HealthScore`, `SubscriptionService`
**Deliverables:**
- Hero image with parallax scroll
- **Liquid Glass health-score ring** (0–100) with per-goal breakdown (tap to expand reasons)
- Warnings section — ember `#C0522F` for high-severity, amber for moderate, forest for low
- Tabs: Uses • Contraindications • Recipes • Ask (AI chat)
- Recipes tab: locked with paywall CTA if `currentTier == .free`
- Suggested prompts row deep-links into Chat with `contextPlantID`
- Premium users see richer reasoning (health-score edge fn auto-routes to Gemini 3 Pro for them — no iOS changes needed)

**Asset freedom:** If a particular plant needs its own hero illustration beyond stock photography, use `variant: "imagen-ultra"` with transparent:false and a themed bone-sage backdrop.

**Tests:** renders free-tier and premium-tier states; health-score ring respects score boundaries (0, 50, 100)

---

## Instance 7 — Recipes

**Skill:** `/swiftui-patterns`
**Owns:** `HerbLens/HerbLens/Features/Recipes/**`
**Depends on:** `Recipe`, `RecipeIngredient`, `RecipeStep`, `SubscriptionService`
**Deliverables:**
- Recipe list component:
  - Tea cards use `tea-card-*.png` backgrounds
  - Tincture cards use a distinct treatment (darker forest-green card with amber label)
  - Header uses `bamboo-brewing.png`
- Recipe detail view:
  - Hero + metadata (prep time, steep/cure time, yield, difficulty)
  - Ingredients list with measurements
  - Step-by-step with tips (swipe between steps OR vertical list)
  - Timer integration for steep time
- Premium gate: full recipes locked for free users; show clear upsell inline on locked recipes
- "Mark as made" state (persisted in UserDefaults keyed by `recipe.id`)

**Asset freedom (explicit):** The core app ships with 2 tea cards (chamomile, peppermint). **You should generate additional tea + tincture cards** as recipes are added — at least 8 tea cards and 4 tincture cards for v1. Reuse the `tea-card-chamomile.json` prompt as the template, swap the plant + color story. Tinctures use glass dropper bottles, not mugs.

**Tests:** premium vs free rendering, timer state

---

## Instance 8 — Vault (Scan history)

**Skill:** `/swiftui-patterns`
**Owns:** `HerbLens/HerbLens/Features/Vault/**`
**Depends on:** `ScansRepository`, `Scan`, `Plant`
**Deliverables:**
- Grid view (2-column) of scanned plants: thumbnail + name + scanned date
- Filter chips: category (Herb/Root/Flower/Bark/Leaf/Berry/Mushroom), favorites only
- Sort menu: date scanned, health score, common name, favorites first
- Long-press or swipe → delete, favorite
- **Empty state:** `bamboo-sleeping.png` centered with "Your vault is quiet — scan your first plant" copy
- Tap → HerbProfile with preloaded plant

**Tests:** filter + sort logic with mock data (include 8+ scans across multiple categories)

---

## Instance 9 — AI Chat (Premium, Bamboo Expert)

**Skill:** `/swiftui-patterns`
**Owns:** `HerbLens/HerbLens/Features/Chat/**`
**Depends on:** `ChatRepository`, `Conversation`, `Message`, `SubscriptionService`, `Plant`
**AI stack:** `ai-chat` edge fn wraps Gemini 3 Flash streaming (SSE). Each event: `data: {"delta":"..."}\n\n` ending with `data: [DONE]`. Consume with `URLSession.bytes(for:)` and parse line-by-line into `AsyncThrowingStream<String, Error>`.

**Deliverables:**
- Conversation list (grouped by date, context plant name in subtitle)
- Thread view with streaming assistant responses
- Input bar with plant-context chip when deep-linked from HerbProfile
- Suggested prompts row pulled from `plant.suggestedPrompts`
- **Bamboo avatar:** `bamboo-teacher.png` (static, committed asset — do NOT regenerate at runtime)
- Premium gate: full lock with paywall CTA for free users
- Typing indicator during stream, error banner on failure

**Tests:** stream consumption + rendering incremental content (fake an AsyncStream in tests)

---

## Instance 10 — Paywall + Settings

**Skill:** `/stripe-best-practices`
**Owns:** `HerbLens/HerbLens/Features/Paywall/**`, `HerbLens/HerbLens/Features/Settings/**`
**Depends on:** `SubscriptionService`, `AuthService`, `UserProfile`, `HealthProfile`

**Deliverables (Paywall):**
- Hero: `scene-apothecary.png` at the top with a warm overlay gradient
- Offerings from `SubscriptionService.offerings()` — monthly and yearly packages
- **Feature comparison table** — explicit "Premium glow" list: unlimited scans, AI Expert Chat with Bamboo, full recipes, deeper health insights (Gemini 3 Pro), premium animations
- Trial badge if offering includes trial days
- Purchase + Restore buttons with loading/error states
- Success state → dismiss and refresh `SubscriptionService.currentTier()`

**Deliverables (Settings):**
- Profile section (display name, avatar, email)
- Health profile editor (reuses Onboarding wizard in edit mode)
- Subscription management row (current tier, manage in App Store deep link, restore purchases)
- Legal: Privacy Policy, Terms of Service, open-source licenses
- Sign out

**Asset freedom:** Generate additional paywall headers if you want to A/B test (e.g. Bamboo surrounded by premium feature icons).

**Tests:** renders free vs premium settings; purchase happy-path with mock service

---

## Coordination

- Every instance: start with `git pull origin main && git checkout -b feat/<your-scope>`
- Instance 1 and 2 should finish first — others should stub locally while waiting
- Use Xcode folder references so new files are picked up without pbxproj edits
- When done, each instance reports back to the user: branch name + list of files + test results
- **If you generate assets**, commit the prompt JSON alongside the accepted image/video to your branch
