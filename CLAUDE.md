# CLAUDE.md — HerbLens

> This file is the shared contract for every Claude Code instance working on HerbLens.
> Read it completely before touching any code. All 10 parallel instances rely on the
> protocols, models, and boundaries defined here.

---

## 1. What we're building

**HerbLens** — iOS app (iOS 26+, SwiftUI, Swift 6.2).
Tagline: *"Scan. Learn. Brew."*

Users photograph herbs/plants, the app identifies them via AI, scores each plant against
the user's health goals, warns about contraindications, and provides step-by-step tea
and tincture recipes. AI Expert Chat and recipes are premium (RevenueCat).

**Canonical data schema:** `herblens_data_structure.json` (project root). That file is
the source of truth for every model, API contract, and view requirement.

---

## 2. Tech stack

| Layer | Tech |
|---|---|
| iOS app | SwiftUI, Swift 6.2 strict concurrency, iOS 26 Liquid Glass |
| Backend | Supabase (Postgres + RLS, Auth, Storage, Edge Functions) |
| AI text + vision | **Google Gemini 2.5 Flash** via Supabase Edge Functions (identify-plant, ai-chat, health-score) |
| AI image gen | **Nano Banana** (`gemini-2.5-flash-image`) via `generate-image` edge fn — collection covers, mascot art, recipe hero shots |
| AI video gen | **Veo 3** (`veo-3.0-generate-001`) via `generate-video` edge fn — onboarding hero, celebration animations, loading loops |
| Payments | RevenueCat (App Store + Stripe cross-platform) |
| Analytics | PostHog |
| Config | `.xcconfig` (Debug/Release) — never commit secrets |

**All Google/Gemini calls stay server-side.** The iOS app never holds `GEMINI_API_KEY`.
It calls Supabase edge functions; Supabase holds the key as a secret:

```bash
supabase secrets set GEMINI_API_KEY=<key from .env GOOGLEAPI>
```

**MCP servers authenticated:** `supabase`, `stripe`, `revenuecat`, `context7`.

**Supabase project ref:** `flrfeymfuuxycfwlmlgy`
**Edge-function base URL:** `https://flrfeymfuuxycfwlmlgy.supabase.co/functions/v1/`
**Endpoints live:** `identify-plant`, `ai-chat`, `health-score`, `generate-image`, `generate-video`, `send-notification`

---

## 3. Directory layout (authoritative)

```
HerbLens/
├── CLAUDE.md                          ← you are here
├── herblens_data_structure.json       ← canonical schema
├── HerbLens/                          ← Xcode project root
│   ├── HerbLens.xcodeproj
│   ├── Config/
│   │   ├── Config.xcconfig.template   ← committed
│   │   ├── Debug.xcconfig             ← gitignored
│   │   └── Release.xcconfig           ← gitignored
│   ├── HerbLens/
│   │   ├── App/                       ← root app entry
│   │   ├── Features/                  ← one folder per feature (Instance N owns one)
│   │   │   ├── Chat/                  ← Instance 9
│   │   │   ├── HerbProfile/           ← Instance 6
│   │   │   ├── Home/                  ← Instance 4
│   │   │   ├── Onboarding/            ← Instance 3
│   │   │   ├── Paywall/               ← Instance 10
│   │   │   ├── Recipes/               ← Instance 7
│   │   │   ├── Scan/                  ← Instance 5
│   │   │   ├── Settings/              ← Instance 10
│   │   │   └── Vault/                 ← Instance 8
│   │   ├── Services/
│   │   │   ├── Live/                  ← Instance 2 (Supabase-backed)
│   │   │   └── Mock/                  ← Instance 2 (for previews/tests)
│   │   ├── Shared/                    ← Instance 1 OWNS THIS
│   │   │   ├── Extensions/
│   │   │   ├── Models/                ← Codable DTOs (contract)
│   │   │   ├── Protocols/             ← service protocols (contract)
│   │   │   └── Theme/                 ← color, typography, spacing, liquid glass
│   │   ├── Resources/
│   │   └── Assets.xcassets/
│   ├── HerbLensTests/
│   └── HerbLensUITests/
└── supabase/
    ├── migrations/                    ← already created
    ├── seed.sql                       ← already created
    └── functions/
        ├── identify-plant/            ← Gemini 2.5 Flash (vision)
        ├── health-score/              ← Gemini 2.5 Flash (structured JSON)
        ├── ai-chat/                   ← Gemini 2.5 Flash (streaming SSE)
        ├── generate-image/            ← Nano Banana (gemini-2.5-flash-image)
        ├── generate-video/            ← Veo 3 (veo-3.0-generate-001, async)
        └── send-notification/
```

---

## 4. Ownership rules (critical for parallel work)

1. **Each instance owns exactly one path prefix.** Do not edit files outside your prefix.
2. **Shared/ is read-only for instances 2–10.** Only Instance 1 writes there.
3. **Services/ is read-only for instances 3–10.** Only Instance 2 writes there.
4. **If you need a type, protocol, or helper that doesn't exist:** stub it *inside your
   feature folder* as `__pending__<Name>.swift` and add a one-line entry to
   `.claude/parallel-instances.md` under "Pending requests to Shared/Services". Do not
   cross into another owner's folder.
5. **Never touch** `HerbLens.xcodeproj/project.pbxproj` by hand — use Xcode file-system
   refs or let the build tooling pick up new files via folder references.
6. **Never commit** `Debug.xcconfig`, `Release.xcconfig`, or any key material.

---

## 5. Shared contracts (Instance 1 must publish these first)

Every other instance codes against these names. Instance 1 implements them exactly.

### 5.1 Codable models (in `Shared/Models/`)

Match `herblens_data_structure.json` field-for-field. snake_case JSON ↔ camelCase Swift via
`JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase`.

- `UserProfile`, `HealthProfile`, `HealthGoal`
- `Plant`, `PlantUse`, `Contraindication`, `HealthScore`, `GoalBreakdown`, `Warning`
- `Recipe`, `RecipeIngredient`, `RecipeStep`
- `Scan`, `HighlightCollection`
- `Conversation`, `Message`
- `SubscriptionTier` (enum: `.free`, `.premium`)

All models are `struct`, `Codable`, `Sendable`, `Identifiable` where an `id` exists.

### 5.2 Service protocols (in `Shared/Protocols/`)

All protocols are `Sendable`. All methods are `async throws`. Use typed throws where practical.

```swift
protocol AuthService: Sendable {
    var currentUserID: String? { get async }
    func signUp(email: String, password: String) async throws -> UserProfile
    func signIn(email: String, password: String) async throws -> UserProfile
    func signOut() async throws
    func sendMagicLink(email: String) async throws
}

protocol PlantsRepository: Sendable {
    func featured() async throws -> [Plant]
    func plant(id: String) async throws -> Plant
    func search(query: String) async throws -> [Plant]
    func healthScore(for plantID: String, userID: String) async throws -> HealthScore
    func highlightCollections() async throws -> [HighlightCollection]
}

protocol ScansRepository: Sendable {
    func identify(imageData: Data) async throws -> IdentifyResult   // calls identify-plant edge fn
    func save(_ scan: Scan) async throws -> Scan
    func list(userID: String, sort: ScanSort, filter: ScanFilter) async throws -> [Scan]
    func toggleFavorite(scanID: String) async throws
    func delete(scanID: String) async throws
}

protocol ChatRepository: Sendable {
    func conversations(userID: String) async throws -> [Conversation]
    func messages(conversationID: String) async throws -> [Message]
    func startConversation(userID: String, contextPlantID: String?) async throws -> Conversation
    func send(message: String, to conversationID: String) -> AsyncThrowingStream<String, Error>
}

protocol SubscriptionService: Sendable {
    func currentTier() async -> SubscriptionTier
    func offerings() async throws -> [Offering]
    func purchase(packageID: String) async throws -> SubscriptionTier
    func restore() async throws -> SubscriptionTier
}

protocol HealthProfileRepository: Sendable {
    func load(userID: String) async throws -> HealthProfile
    func save(_ profile: HealthProfile) async throws
}
```

### 5.3 Theme (in `Shared/Theme/`)

- `Theme.Color` — earthy/herbal palette (sage, forest, bone, amber, ember for warnings)
- `Theme.Font` — SF Pro with custom display face; `title`, `headline`, `body`, `caption`
- `Theme.Spacing` — 4/8/12/16/24/32 scale
- `Theme.Glass` — Liquid Glass material tokens (iOS 26)

### 5.4 DI container (in `App/`)

`AppDependencies` — struct with all services. Build a live version for `@main` and a mock
version for Xcode Previews. All feature views accept dependencies via `@Environment` or
initializer injection.

---

## 6. Environment & config

Read secrets from `Info.plist` (populated by `.xcconfig`), never hardcode:

```swift
enum AppConfig {
    static let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as! String
    static let supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as! String
    static let revenueCatKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as! String
}
```

Required `.xcconfig` keys (see `Config.xcconfig.template`):
`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `REVENUECAT_API_KEY`, `POSTHOG_API_KEY`, `POSTHOG_HOST`.

**Gemini API key is server-only** — set once via `supabase secrets set GEMINI_API_KEY=<value>`.

---

## 7. Testing

- Framework: **Swift Testing** (`import Testing`, `@Test`, `#expect`)
- Each feature ships with tests in `HerbLensTests/<Feature>/`
- Use the mock services from `Services/Mock/` — never hit the network in unit tests
- Target ≥80% coverage per feature module

---

## 8. Commit discipline

- Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`
- One feature = one branch per instance (e.g. `feat/scan`, `feat/vault`) — the user will
  merge when each instance reports done.
- Do not push or open PRs without explicit user instruction.

---

## 9. See also

- `.claude/parallel-instances.md` — full briefs for all 10 instances and a pending-requests log
- `herblens_data_structure.json` — canonical schema
- `supabase/migrations/20260415000001_initial_schema.sql` — DB shape
- `supabase/functions/*` — edge function contracts for identify-plant, health-score, ai-chat, send-notification

---

## 10. Notes for downstream instances

Findings logged by earlier instances so you don't repeat the archaeology. If you
discover something that will save the next instance time, append here.

### 10.1 Concurrency: types are `@MainActor` by default — mark data `nonisolated` (Instance 1)

The project is configured with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and
`SWIFT_APPROACHABLE_CONCURRENCY = YES` (Swift 6.2/6.3 approachable-concurrency
mode). Every declaration you write inherits `@MainActor` unless you opt out.

This is the right default for UI/view code — but it is *wrong* for `Sendable`
value types. A `@MainActor`-isolated struct cannot actually cross isolation
boundaries cleanly, and its inits/properties become unreachable from actors
and nonisolated async contexts. You will see errors like:

- *"main actor-isolated initializer cannot be called from outside of the actor"*
- *"main actor-isolated default value in a nonisolated context"*
- *"main actor-isolated static property 'X' can not be referenced from a nonisolated context"*

**Rule of thumb:** mark any pure data type, DTO, or static-token namespace
`nonisolated`. Leave view code, `@Observable` models, and stateful singletons
as the `@MainActor` default.

```swift
// Codable DTO — crosses actor boundaries, must be nonisolated.
public nonisolated struct Plant: Codable, Sendable, Identifiable, Hashable { … }

// Static design-token namespace — accessed from previews, tests, and feature
// code in any isolation context.
public nonisolated enum Theme { … }
public extension Theme { nonisolated enum Color { … } }

// Hex-parsing init on SwiftUI.Color — callable from nonisolated static stored
// properties, so the init itself must be nonisolated.
public extension Color { nonisolated init?(hex: String) { … } }

// SwiftUI views, view models, observable state — keep the @MainActor default.
struct HomeView: View { … }
```

Shared/Models, Shared/Theme, App/AppDependencies, App/SampleData, and
App/MockServices already follow this pattern — copy it when you add your own
DTOs or static token namespaces.

### 10.2 Swift language mode (Instance 1)

Project is pinned at **Swift 6.3** (was 5.0 in the initial commit; bumped in
the Instance-1 pbxproj edit). If you add new Xcode targets, match the version.

### 10.3 Synchronized folder groups — new files are auto-picked-up (Instance 1)

The Xcode project uses `PBXFileSystemSynchronizedRootGroup`. **Do not edit
`project.pbxproj` to register new Swift files** — drop them into any folder
under `HerbLens/HerbLens/**` or `HerbLens/HerbLensTests/**` and they are
compiled automatically. Xcode's SourceKit index can lag; if autocomplete shows
"Cannot find type X" errors immediately after creating a file, trust
`xcodebuild` over the in-editor diagnostics.

### 10.4 `.gitkeep` files are excluded from the bundle (Instance 1)

`EXCLUDED_SOURCE_FILE_NAMES = .gitkeep` is set on every target. Synced folder
groups would otherwise copy every `.gitkeep` to the same output path
(`HerbLens.app/.gitkeep`) and fail the build with duplicate-output errors.
When you populate a previously-empty feature/service folder, you can delete
its `.gitkeep` — it is no longer needed.

### 10.5 SPM pins (Instance 1)

`supabase-swift` is pinned to `2.43.1`, not the `3.0.0` the initial pbxproj
asked for (no 3.x release exists). `Package.resolved` is committed; do not
bump these without coordinating with Instance 2.

### 10.6 JSON decoder strategy (Instance 1)

`herblens_data_structure.json` uses **camelCase keys** despite §5.1's
`.convertFromSnakeCase` guidance. Both work: camelCase passes through the
strategy unchanged, and real Supabase/Postgres snake_case responses convert
correctly. Keep `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase` set
so the same decoder handles both the schema fixture and the wire format.

### 10.7 `AppDependencies.live` is a `fatalError` until Instance 2 lands (Instance 1)

`AppDependencies.live(supabaseURL:supabaseAnonKey:)` currently traps. The
`@main` entry wires `.mock` so the app boots. Instance 2 will replace the body
of `.live(...)` and swap `HerbLensApp.dependencies` to the live factory. Don't
call `.live` from previews or tests — use `.mock`.

### 10.8 Mocks moved to `Services/Mock/` (Instance 2)

`MockServices.swift` and `SampleData.swift` now live at
`HerbLens/HerbLens/Services/Mock/` (canonical per §3), not `App/`. The symbol
names didn't change, so `AppDependencies.mock` and any `#Preview` calling
`MockServices.X()` still works. Seed expanded from 1 → 5 plants:
chamomile, peppermint, ginger, lavender, echinacea — `SampleData.plants`,
`SampleData.highlightCollections`, `SampleData.scans` all return arrays now.

### 10.9 Live services accept injectable client + `baseURL` for tests (Instance 2)

Every `Supabase*Repository` init takes optional `client`, `session`, and
`baseURL` parameters. Defaults read `SupabaseClientProvider.shared` /
`URLSession.shared` / `AppConfig.supabaseURL` lazily, *not* at init time, so
constructing a repo never trips the AppConfig fatal — that only fires when an
actual edge-fn URL is built. Tests should pass `URLProtocolStub.session()` +
`baseURL: URL(string: "http://localhost.invalid")!` so no AppConfig lookup
happens. Auth-bearer tokens come from `self.client.auth.session.accessToken`,
not the global provider — provide a stub `SupabaseClient` (or use
`HerbLensTests/Services/TestSupabaseClient.noop`) when constructing repos in
tests.

### 10.10 Typed errors live services raise (Instance 2)

Pattern-match these in feature code rather than `as NSError`:

- `ServiceError.unauthenticated` — no Supabase session; route to sign-in.
- `ServiceError.httpStatus(Int, body: String?)` — non-200 from an edge fn.
- `ServiceError.decodingFailed(String)` — DTO mismatch; surfaces server bugs.
- `ChatError.httpStatus(Int)` — `ai-chat` SSE refused the stream.
- `ChatError.malformedEvent(String)` — SSE chunk wasn't `data: {"delta":...}`.

Note: `ScanError.quotaExceeded` was removed — all users get unlimited scans.
Premium gates content depth (health score breakdowns, recipes, AI chat, detailed
warnings), not scan count. The paywall is triggered by tier-based UI gates in
feature views, not by service-layer errors.

### 10.11 Swift 6.2 `nonisolated` is required for test access (Instance 2)

Extends §10.1 with the test-time corollary. With `MainActor` as the default
isolation, anything a Swift Testing `#expect` closure or a test method touches
needs to be reachable from a non-main context:

- **Initializers** of types you construct in tests: `public nonisolated init(...)`.
- **`static let` constants** referenced by `#expect`:
  `public nonisolated static let ...`.
- **Nested types whose `Equatable` conformance is compared by `#expect`**
  (e.g. `LineEvent`): mark the type *and* its `static let` members
  `nonisolated`.
- **`@unchecked Sendable` final classes** (e.g. `RevenueCatSubscriptionService`)
  still need `nonisolated init(...)` because the implicit `MainActor` defaults
  also infer onto inits.
- **Actor inits** *cannot* be `nonisolated` — Swift 6.2 rejects it. Just leave
  actor inits unannotated; tests reach them via `await MockServices.Scans()`.

Without this, you'll see `main actor-isolated initializer 'init()' cannot be
called from outside of the actor` errors that can't be fixed in the test file.

### 10.12 Low-RAM xcodebuild runner — use it (Instance 2)

`scripts/test-services-low-mem.sh` runs `xcodebuild` with `-jobs 2`, no
parallel testing, the smallest available iPhone simulator, and
`SWIFT_COMPILATION_MODE=singlefile`. The default xcodebuild invocation parallel-
compiles every SPM dep (Supabase + RevenueCat + Sentry + PostHog + Kingfisher)
across all cores **and** boots a full simulator on top — on a 16 GB Mac that
crashes the OS. Use the script for local test runs:

```bash
scripts/test-services-low-mem.sh                    # full test pass
scripts/test-services-low-mem.sh --build-only       # app build only
scripts/test-services-low-mem.sh --build-tests-only # also compile test bundle
scripts/test-services-low-mem.sh --test-without-build
scripts/test-services-low-mem.sh --verbose          # full xcodebuild output
```

Logs land in `scripts/.logs/test-services-<timestamp>.log`. The script
filters output to compiler errors, warnings, and Swift Testing pass/fail
lines — pipe through `--verbose` if you need raw xcodebuild output. If the
simulator gets stuck "Busy" between runs, `xcrun simctl shutdown all`
unsticks it.
