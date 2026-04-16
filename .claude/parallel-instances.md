# HerbLens — Parallel Instance Briefs

10 concurrent Claude Code instances, one per workstream. Read `CLAUDE.md` first.

**Before starting your instance:** always run `git pull` and `git checkout -b feat/<your-feature>`.
**When done:** commit to your branch, do NOT merge or push. The user merges.

---

## Pending requests to Shared/Services

If you need something from Shared/ or Services/ that doesn't exist, append a line here.
Instance 1 or 2 will pick it up.

- (empty)

---

## Instance 1 — Shared Foundation (Models, Protocols, Theme)

**Skill:** `/swiftui-patterns`
**Owns:** `HerbLens/HerbLens/Shared/**`, `HerbLens/HerbLens/App/**`
**Depends on:** nothing — run first
**Deliverables:**
- All Codable models from `herblens_data_structure.json` in `Shared/Models/`
- All service protocols listed in CLAUDE.md §5.2 in `Shared/Protocols/`
- `Shared/Theme/` — color palette, typography, spacing, Liquid Glass tokens
- `Shared/Extensions/` — `Color+Hex`, `Date+Relative`, `View+Conditional`
- `App/AppDependencies.swift` — DI container with live + mock factories
- `App/HerbLensApp.swift` — inject dependencies via `@Environment`
- Unit tests for every model (round-trip JSON decode of the sample plant entry)

---

## Instance 2 — Services (Live + Mock)

**Skill:** `/swift-protocol-di-testing`
**Owns:** `HerbLens/HerbLens/Services/**`
**Depends on:** Instance 1 protocols/models (stub locally if not ready)
**Deliverables:**
- `Services/Live/SupabaseClientProvider.swift` — singleton client from `AppConfig`
- `Services/Live/SupabaseAuthService.swift` → conforms to `AuthService`
- `Services/Live/SupabasePlantsRepository.swift` → conforms to `PlantsRepository`
- `Services/Live/SupabaseScansRepository.swift` → calls identify-plant edge fn, saves to `scans` table
- `Services/Live/SupabaseChatRepository.swift` → streams from ai-chat edge fn
- `Services/Live/SupabaseHealthProfileRepository.swift`
- `Services/Live/RevenueCatSubscriptionService.swift` → conforms to `SubscriptionService`
- `Services/Mock/Mock*.swift` — in-memory versions returning fixture data
- Tests: each live service exercised against mock responses

---

## Instance 3 — Onboarding + Auth

**Skill:** `/swiftui-patterns`
**Owns:** `HerbLens/HerbLens/Features/Onboarding/**`
**Depends on:** `AuthService`, `HealthProfileRepository`, `UserProfile`, `HealthProfile`, `HealthGoal`
**Deliverables:**
- Welcome screen with value prop + "Scan. Learn. Brew." tagline
  - Hero animation: call `generate-video` edge function (Veo 3) once at build time to produce
    a looping 6-second clip of herbs swaying/pouring tea. Store in `Resources/` as `welcome.mp4`
    and play with `AVPlayer` in the view. Fallback to a static image while loading.
- Sign-up / Sign-in (email + magic link) using `AuthService`
- Multi-step health profile wizard:
  1. Primary health goals (Sleep, Digestive, Stress, Immunity, Skin, Pain, Energy, Focus) — ranked
  2. Allergies (tag input with common presets)
  3. Medications (tag input)
  4. Conditions (pregnant, breastfeeding, high blood pressure, diabetes, etc.)
  5. Experience level (beginner/intermediate/advanced)
- On finish → set `user_profiles.onboarding_completed = true`
- Tests for view state transitions

---

## Instance 4 — Home / Explore

**Skill:** `/swiftui-patterns`
**Owns:** `HerbLens/HerbLens/Features/Home/**`
**Depends on:** `PlantsRepository`, `Plant`, `HighlightCollection`
**Deliverables:**
- Home feed with:
  - Big scan CTA button at top
  - Featured plants carousel
  - Highlight collections sections (e.g. "Sleep Aids", "Digestive Support")
    - Collection cover art: call `generate-image` edge function (Nano Banana) one-off per
      collection to produce a painterly hero image. Cache the returned base64 to Supabase
      Storage and store the URL on `highlight_collections.cover_image_url`.
  - "Recently scanned" quick-access row (from Vault)
- Pull-to-refresh
- Tap plant → push to HerbProfile feature (use `NavigationStack` path binding)
- Tests: renders with mock repository data

---

## Instance 5 — Scan (Camera + Gemini Identify)

**Skill:** `/swiftui-patterns`
**Owns:** `HerbLens/HerbLens/Features/Scan/**`
**Depends on:** `ScansRepository`, `PlantsRepository`
**AI stack:** The `identify-plant` edge function wraps **Gemini 2.5 Flash vision**.
The iOS app ships the image as base64 and receives `{ plant_name, confidence,
scientific_name, properties[], description, candidates[] }` with structured JSON output.
**Deliverables:**
- Camera capture (AVFoundation) + PhotosPicker fallback
- Downscale + JPEG-compress to ≤1024px on-device before upload (save tokens)
- Loading state while `identify-plant` edge function runs
- Result card with confidence score, identified plant name, primary image
- CTA: "Save to Vault" / "Scan another"
- Low-confidence flow (confidence < 0.75): show `candidates[]` so user picks
- Success animation: optionally call `generate-video` (Veo 3) once to produce a
  celebration clip played on successful identification — cache locally
- Haptics on successful identify
- Tests with mock `ScansRepository` returning fixture identify results

---

## Instance 6 — Herb Profile (Plant detail)

**Skill:** `/liquid-glass-design`
**Owns:** `HerbLens/HerbLens/Features/HerbProfile/**`
**Depends on:** `PlantsRepository`, `Plant`, `HealthScore`, `SubscriptionService`
**Deliverables:**
- Hero image with parallax scroll
- Liquid Glass health-score ring (0–100) with per-goal breakdown (tap to expand reasons)
- Warnings section (allergies / medication / condition) — ember color, high-severity badge
- Tabs: Uses • Contraindications • Recipes • Ask (AI chat)
- Recipes tab: locked with paywall CTA if `currentTier == .free`
- Suggested prompts row that deep-links into Chat feature with `contextPlantID`
- Tests: renders free-tier and premium-tier states

---

## Instance 7 — Recipes

**Skill:** `/swiftui-patterns`
**Owns:** `HerbLens/HerbLens/Features/Recipes/**`
**Depends on:** `Recipe`, `RecipeIngredient`, `RecipeStep`, `SubscriptionService`
**Deliverables:**
- Recipe list component (tea cards and tincture cards, different visual treatment)
- Recipe detail view:
  - Hero + metadata (prep time, steep/cure time, yield, difficulty)
  - Ingredients list with measurements
  - Step-by-step with tips (swipe between steps, or vertical list)
  - Timer integration for steep time
- Premium gate: full locking for free users with clear upsell
- "Mark as made" state (persisted in UserDefaults keyed by recipe.id)
- Tests: premium vs free rendering

---

## Instance 8 — Vault (Scan history)

**Skill:** `/swiftui-patterns`
**Owns:** `HerbLens/HerbLens/Features/Vault/**`
**Depends on:** `ScansRepository`, `Scan`, `Plant`
**Deliverables:**
- Grid view (2-column) of scanned plants with thumbnail + name + scanned date
- Filter chips: category (Herb/Root/Flower/Bark/Leaf/Berry/Mushroom), favorites only
- Sort menu: date scanned, health score, common name, favorites first
- Long-press or swipe → delete, favorite
- Empty state with CTA back to Scan
- Tap → HerbProfile with preloaded plant
- Tests: filter + sort logic with mock data

---

## Instance 9 — AI Chat (Premium, Gemini)

**Skill:** `/swiftui-patterns`
**Owns:** `HerbLens/HerbLens/Features/Chat/**`
**Depends on:** `ChatRepository`, `Conversation`, `Message`, `SubscriptionService`, `Plant`
**AI stack:** The `ai-chat` edge function wraps **Gemini 2.5 Flash streaming** (SSE).
Each SSE event is `data: {"delta":"..."}\n\n` ending with `data: [DONE]`.
Consume with `URLSession.bytes(for:)` and parse line-by-line into an
`AsyncThrowingStream<String, Error>`.
**Deliverables:**
- Conversation list (grouped by date, context plant name in subtitle)
- Thread view with streaming assistant responses (`AsyncThrowingStream<String, Error>`)
- Input bar with plant-context chip when deep-linked from HerbProfile
- Suggested prompts row pulled from `plant.suggestedPrompts`
- Premium gate: full lock with paywall for free users
- Typing indicator during stream, error banner on failure
- Bamboo panda avatar (static PNG committed as asset — do NOT call generators at runtime)
- Tests: stream consumption + rendering incremental content

---

## Instance 10 — Paywall + Settings (RevenueCat wiring)

**Skill:** `/stripe-best-practices`
**Owns:** `HerbLens/HerbLens/Features/Paywall/**`, `HerbLens/HerbLens/Features/Settings/**`
**Depends on:** `SubscriptionService`, `AuthService`, `UserProfile`, `HealthProfile`
**Deliverables (Paywall):**
- Offerings displayed from `SubscriptionService.offerings()` — monthly and yearly packages
- Feature comparison table (Free vs HerbLens Pro)
- Trial badge if offering includes trial days
- Purchase + Restore buttons with loading/error states
- Success state → dismiss and refresh `SubscriptionService.currentTier()`

**Deliverables (Settings):**
- Profile section (display name, avatar, email)
- Health profile editor (goals / allergies / medications / conditions — edit same wizard from Onboarding in edit mode)
- Subscription management row (current tier, manage in App Store deep link, restore purchases)
- Legal: Privacy Policy, Terms of Service, open-source licenses
- Sign out
- Tests: renders free vs premium settings

---

## Coordination

- Every instance: start with `git pull origin main && git checkout -b feat/<your-scope>`
- Instance 1 and 2 should finish first — others should stub locally while waiting.
- Use Xcode folder references so new files are picked up without pbxproj edits.
- When done, each instance reports back to the user: branch name + list of files + test results.
