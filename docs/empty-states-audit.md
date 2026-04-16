# Empty + Error States Audit

Generated: 2026-04-16
Method: read-only sweep across all 8 Feature worktrees on 2026-04-16.
Source of truth for the shared component: `HerbLens/HerbLens/Shared/Components/EmptyStateView.swift` (published on `feat/design-system`).
Owner of this audit: Agent C6 (`feat/empty-states`). No Features/ files were modified.

## Summary

| Metric | Count |
|---|---|
| Total empty / loading / error code paths found | **34** |
| Already using shared `EmptyStateView` | **2** (Scan: `permissionPrompt`, `unavailablePrompt`) |
| Using bespoke "EmptyView"/illustration card with prose Bamboo asset | **5** (Vault, Onboarding `FinalizingView`, HerbProfile `EmptyContraindicationsCard`, HerbProfile `EmptyRecipesCard`, Chat `emptyState`) |
| Using bare `Image(systemName: "exclamationmark.*")` error block | **6** (Scan, Home, Onboarding, HerbProfile, Chat list, Settings legal subnav) |
| Using bare `ProgressView()` with no mascot | **11** (Vault, Recipes, Home, Onboarding, HerbProfile hero + load, Chat list, Chat thread, Chat root, Paywall offerings + restore + buy, Settings save + sub) |
| Recommended for migration to `EmptyStateView` | **17** |
| Acceptable as-is (inline list separators, validation, etc.) | **15** |

The shared component has been imported correctly only in `ScanIdleView` (2 call sites). Every other feature predates the design-system merge and rolls its own VStack-of-Image-and-Text. **Top-line finding:** the visual language for "nothing here / something broke" diverges across all 8 features.

## Per-Feature audit

### Scan (`feat/scan`) — `/Users/amadeobonde/Desktop/HerbLens/HerbLens/HerbLens/Features/Scan`

| File | Line | Pattern | Status | Recommended fix |
|---|---|---|---|---|
| `Views/ScanIdleView.swift` | 110-116 | `permissionPrompt` — uses `EmptyStateView(mascot: .sleeping, ...)` | Already migrated | Add a "Open Settings" CTA via `ctaTitle:`/`action:` (`UIApplication.openSettingsURLString`) — currently the user has no path forward. |
| `Views/ScanIdleView.swift` | 118-124 | `unavailablePrompt` — uses `EmptyStateView(mascot: .sleeping, ...)` | Already migrated | Add `ctaTitle: "Pick from library"` so the CTA matches the library button below the viewfinder. |
| `Views/ScanView.swift` | 77-106 | `ScanErrorOverlay` — bespoke `Image(systemName: "exclamationmark.triangle.fill")` + Text + capsule retry button | Migration | Replace with `EmptyStateView(mascot: .sleeping, title: error.title, subtitle: error.message, ctaTitle: error.retriable ? "Try again" : "OK", action: onDismiss)`. |
| `Views/ScanLoadingView.swift` | 23-65 | Custom loading: `MascotBadge(.scanning, size: 180)` rotating + rotating copy in a `GlassCard` | Acceptable as-is | Already follows the proposed loading pattern (animated mascot + chip). Can be lifted as `LoadingMascotView` later — leave for now. |
| `Views/QuotaReachedView.swift` | 9-50 | Bespoke quota CTA: `Image(systemName: "moon.stars.fill")` halo + Text + capsule "Go Premium" | Migration | Replace with `EmptyStateView(mascot: .sleeping, title: "That's your \(limit) for today", subtitle: "Premium unlocks unlimited scans, AI chat with Bamboo, and full recipes.", ctaTitle: "Go Premium", action: onPaywall)`. The "Come back tomorrow" button can stay as a secondary text button beneath. |

### Recipes (`feat/recipes`) — `/Users/amadeobonde/Desktop/HerbLens-recipes/HerbLens/HerbLens/Features/Recipes`

| File | Line | Pattern | Status | Recommended fix |
|---|---|---|---|---|
| `RecipesHomeView.swift` | 45-49 | `if recipes.isEmpty { ProgressView() }` — bare loader, no copy | Migration | Replace with `EmptyStateView(mascot: .brewing, title: "Brewing the catalogue…", subtitle: nil)` while loading; switch to a real empty state if `recipes` stays empty after load (currently masked by `RecipePreviewFixtures` fallback). |
| `RecipesHomeView.swift` | 159-161 | `catch { recipes = RecipePreviewFixtures.allRecipes }` — silent fixture fallback | Acceptable as-is, but flag | Consider surfacing a non-blocking toast when the fetch failed — today the user never knows the network is down. |
| `RecipesHomeView.swift` | 183-186 | `catch { /* fails silently */ }` on upgrade | Acceptable as-is | Comment already notes Paywall (Instance 10) owns the surfaced UX — covered by paywall view's own `errorBanner`. |

### Vault (`feat/vault`) — `/Users/amadeobonde/Desktop/HerbLens-vault/HerbLens/HerbLens/Features/Vault`

| File | Line | Pattern | Status | Recommended fix |
|---|---|---|---|---|
| `VaultView.swift` | 57-59 | `if model.isLoading && model.scans.isEmpty { ProgressView() }` | Migration | Replace with `EmptyStateView(mascot: .scanning, title: "Loading your vault…")` — give a mascot to the empty initial load. |
| `VaultView.swift` | 60-61 | `else if model.scans.isEmpty { VaultEmptyStateView() }` | Migration | `VaultEmptyStateView` is bespoke (uses raw `Image("BambooSleeping")` instead of `MascotBadge`, no CTA). Replace its body with `EmptyStateView(mascot: .sleeping, title: "Your vault is quiet", subtitle: "Scan your first plant to start building your personal apothecary.", ctaTitle: "Scan a plant", action: { /* route to Scan tab */ })`. |
| `VaultView.swift` | 77-80 | `if model.displayedRows.isEmpty { VaultNoMatchesView { clearFilters } }` | Migration | `VaultNoMatchesView` uses `Image(systemName: "line.3.horizontal.decrease.circle")` instead of mascot. Replace with `EmptyStateView(mascot: .default, title: "No matches", subtitle: "Try a different filter or clear your selection.", ctaTitle: "Clear filters", action: onClear)`. |
| `VaultViewModel.swift` | 107-108 | `errorMessage = "Something went wrong loading your vault."` | Acceptable as-is | `errorMessage` is set but **not currently rendered in `VaultView.swift`**. Bug to file: surface this string via an inline banner or, on initial load failure, a full-bleed `EmptyStateView(mascot: .sleeping, title: "Couldn't load your vault.", subtitle: errorMessage, ctaTitle: "Try again", action: load)`. |
| `VaultViewModel.swift` | 118-120 | `errorMessage = "Couldn't update favorite. Try again."` | Acceptable as-is | Toast-shaped — keep inline, but render it in the view. |
| `VaultViewModel.swift` | 129-131 | `errorMessage = "Couldn't delete scan. Try again."` | Acceptable as-is | Same as above — render in view. |

### Home (`feat/home`) — `/private/tmp/herblens-home/HerbLens/HerbLens/Features/Home`

| File | Line | Pattern | Status | Recommended fix |
|---|---|---|---|---|
| `HomeView.swift` | 55-65 | `loadingView` — bare `ProgressView()` + caption "Gathering today's herbs…" | Migration | Replace with `EmptyStateView(mascot: .scanning, title: "Gathering today's herbs…")`. |
| `HomeView.swift` | 67-94 | `errorView(message:)` — `Image(systemName: "exclamationmark.triangle.fill")` + retry capsule | Migration | Replace with `EmptyStateView(mascot: .sleeping, title: "Couldn't load Home", subtitle: message, ctaTitle: "Retry", action: { Task { await viewModel?.load() } })`. |
| `__pending__PlantDetailDestination.swift` | 38 | `ProgressView()` in plant-detail destination stub | Acceptable as-is | Pending stub owned by HerbProfile (Instance 6). Will be deleted at integration. |
| `__pending__PlantDetailDestination.swift` | 51-54 | `catch { /* no error UI */ }` | Acceptable as-is | Pending stub — superseded by HerbProfile's own error state. |

### Onboarding (`feat/onboarding`) — `/Users/amadeobonde/Desktop/HerbLens-onboarding/HerbLens/HerbLens/Features/Onboarding`

| File | Line | Pattern | Status | Recommended fix |
|---|---|---|---|---|
| `OnboardingFlowView.swift` | 88-105 | `FinalizingView` — `Image("bamboo-brewing")` + `ProgressView()` + "Brewing your profile…" | Migration | Replace with `EmptyStateView(mascot: .brewing, title: "Brewing your profile…")` — drops the redundant `ProgressView`, picks up the spring-in mascot animation. |
| `OnboardingFlowView.swift` | 107-128 | `FailureView` — `Image(systemName: "exclamationmark.triangle.fill")` + "Try again" `OnboardingPrimaryButton` | Migration | Replace with `EmptyStateView(mascot: .sleeping, title: message, ctaTitle: "Try again", action: onRetry)`. The bespoke `OnboardingPrimaryButton` styling can be retained via a custom CTA wrapper if needed, but `PrimaryButton` (used by `EmptyStateView`) already matches. |
| `OnboardingViewModel.swift` | 56, 78-83, 170 | Three `catch` blocks — populate `viewModel.error` propagated through `FailureView` | Acceptable as-is | Already routes through `FailureView`; once that migrates, these are good. |
| `Components/OnboardingButton.swift` | 13 | `ProgressView()` inside CTA when async | Acceptable as-is | Inline button-spinner pattern; mascot would be overkill. |

### HerbProfile (`feat/herb-profile`) — `/Users/amadeobonde/Desktop/HerbLens-herb-profile/HerbLens/HerbLens/Features/HerbProfile`

| File | Line | Pattern | Status | Recommended fix |
|---|---|---|---|---|
| `HerbProfileView.swift` | 142-152 | `HerbProfileLoadingPlaceholder` — `ProgressView().tint(forest)` + "Loading plant details…" | Migration | Replace with `EmptyStateView(mascot: .scanning, title: "Loading plant details…")`. |
| `HerbProfileView.swift` | 154-178 | `HerbProfileErrorState` — `Image(systemName: "exclamationmark.circle.fill")` + raw `String(describing: error)` + `.glassProminent` retry | Migration | Replace with `EmptyStateView(mascot: .sleeping, title: "Couldn't load this plant.", subtitle: friendlyMessage(error), ctaTitle: "Try again", action: onRetry)`. **Critical:** `String(describing: error)` is leaking raw Swift error descriptions to users — friendly mapping needed regardless. |
| `Subviews/HeroParallaxHeader.swift` | 26 | `.overlay(ProgressView().tint(Theme.Color.forest))` over hero photo placeholder | Acceptable as-is | Inline image-loading spinner; `EmptyStateView` would be too heavy for a hero placeholder. |
| `Subviews/RecipesTab.swift` | 99-112 | `EmptyRecipesCard` — `Image(systemName: "cup.and.saucer")` + "No recipes catalogued for this plant yet." | Migration (sub-card variant) | This is a *card-sized* empty state inside a tab, not full-screen. `EmptyStateView` is sized for full-bleed (`maxHeight: .infinity`). **Recommendation:** add a `EmptyStateView.compact` (or similar) variant that drops the spacer and uses the smaller mascot — or leave this as-is and document the divergence. |
| `Subviews/ContraindicationsTab.swift` | 65-83 | `EmptyContraindicationsCard` — `Image(systemName: "checkmark.seal.fill")` + "No known contraindications on file." + clinician footnote | Migration (sub-card variant) | Same as above — needs a card-sized variant. The footnote ("Always confirm with your clinician") is feature-specific copy; preserve as `subtitle`. |

### Chat (`feat/chat`) — `/Users/amadeobonde/Desktop/HerbLens-chat/HerbLens/HerbLens/Features/Chat`

| File | Line | Pattern | Status | Recommended fix |
|---|---|---|---|---|
| `Views/ChatRootView.swift` | 43 | `ProgressView().tint(Theme.Color.sage)` while bootstrapping | Migration | Replace with `EmptyStateView(mascot: .teacher, title: "Waking Bamboo…")`. |
| `Views/ChatListView.swift` | 17, 38-42 | Two bare `ProgressView()` blocks (loading conversation list) | Migration | Replace with `EmptyStateView(mascot: .teacher, title: "Loading your chats…")`. |
| `Views/ChatListView.swift` | 52-78 | `emptyState` — `BambooAvatarView(size: 120)` + headline + body + "Start a conversation" capsule CTA | Migration | Replace with `EmptyStateView(mascot: .teacher, title: "Your chat with Bamboo is quiet", subtitle: "Ask anything — brewing, safety, the best herb for your goals.", ctaTitle: "Start a conversation", action: onStartBlank)`. |
| `Views/ChatListView.swift` | 119-138 | `failedState` — `Image(systemName: "exclamationmark.triangle.fill")` + message + `.bordered` "Try again" | Migration | Replace with `EmptyStateView(mascot: .sleeping, title: "Couldn't load your chats.", subtitle: message, ctaTitle: "Try again", action: { Task { await viewModel.load() } })`. |
| `Views/ChatThreadView.swift` | 18 | `ProgressView().tint(Theme.Color.sage)` while bootstrapping a thread | Acceptable as-is | Brief — only flashes during the synchronous-feeling jump from list. Could replace with smaller mascot but low impact. |
| `Components/ChatErrorBanner.swift` | 1-32 | Inline error banner with dismiss `xmark` | Acceptable as-is | This is a **toast pattern**, not an empty state. Keep. (Though the `Theme.Color.amber` background is the right cross-feature pattern for inline errors — see "Cross-cutting" below.) |
| `Components/AssistantTypingBubble.swift` | — | (Existing typing-dots animation — not an empty state) | Acceptable as-is | Bubble-level loading; correct pattern. |
| `ViewModels/ChatThreadViewModel.swift` | 130-133 | `errorBanner = Self.friendly(error)` — already friendly-mapped | Acceptable as-is | Best example of error mapping in the codebase; lift the `friendly(_:)` pattern across other features. |

### Paywall + Settings (`feat/paywall-settings`) — `/Users/amadeobonde/Desktop/HerbLens-paywall/HerbLens/HerbLens/Features/{Paywall,Settings}`

| File | Line | Pattern | Status | Recommended fix |
|---|---|---|---|---|
| `Paywall/PaywallView.swift` | 69-76 | Loading offerings: `ProgressView()` + "Loading plans…" inline HStack | Acceptable as-is | Inline because it sits inside the offerings card; full mascot would be visually heavy here. |
| `Paywall/PaywallView.swift` | 77-80 | `else if viewModel.sortedOfferings.isEmpty { Text("Plans aren't available right now.") }` | Migration (compact) | Replace with a card-sized empty state once sub-card variant exists. Today, no mascot, no CTA. |
| `Paywall/PaywallView.swift` | 110-112, 137-139 | Inline `ProgressView()` inside the purchase + restore CTA buttons | Acceptable as-is | In-button spinner is correct pattern. |
| `Paywall/PaywallView.swift` | 152-162 | `errorBanner(_ message:)` — Text on a translucent ember tinted RoundedRectangle | Acceptable as-is | Toast pattern, parallels `ChatErrorBanner`. **Consolidate:** lift to a shared `InlineErrorBanner` component (see cross-cutting #5). |
| `Settings/SettingsView.swift` | 85-95 | `errorBanner(_ message:)` — duplicate of paywall version | Migration (consolidation) | Same component as above — extract to shared. |
| `Settings/SettingsHealthSection.swift` | 221 | `if isSaving { ProgressView() }` — inline save spinner | Acceptable as-is | Inline button state; correct. |
| `Settings/SettingsSubscriptionSection.swift` | 81 | `ProgressView().controlSize(.small)` for restoring | Acceptable as-is | Inline button state; correct. |
| `Settings/SettingsLegalSection.swift` | 83 | `Image(systemName: "exclamationmark.triangle.fill")` — appears in a row label, not an error UI | Acceptable as-is | Decorative icon for medical-disclaimer row; not an empty state. |

## Cross-cutting recommendations

1. **Adopt `EmptyStateView(mascot:, title:, subtitle:, ctaTitle:, action:)` everywhere a feature renders a full-bleed "nothing here / loading / failed" view.** The component already exists on `feat/design-system` — just import + call.

2. **Map each context to a Bamboo variant.** Available today: `.default`, `.scanning`, `.celebrating`, `.brewing`, `.sleeping`, `.teacher`. There is **no `.confused` or `.thinking` variant**. Proposed mapping:

   | Context | Variant |
   |---|---|
   | No camera / no permission | `.sleeping` |
   | Vault is empty | `.sleeping` |
   | Chat is empty / loading | `.teacher` |
   | Generic loading (Home, HerbProfile, ChatRoot) | `.scanning` |
   | Recipe / onboarding "brewing" | `.brewing` |
   | Server error (any feature) | `.sleeping` (fallback — file follow-up to ship a `.confused` asset) |
   | Long thinking AI response | use `AssistantTypingBubble` (already exists) — no mascot needed |
   | Quota / paywall trigger | `.sleeping` |
   | Onboarding success | `.celebrating` (already used by `CompletionView`) |

3. **Every empty state SHOULD have a CTA when one exists.** Two of the migrated `EmptyStateView` callers in Scan currently pass no `ctaTitle:` even though obvious actions exist ("Open Settings" for permission denial, "Pick from library" for unavailable hardware). Backfill these.

4. **Loading states SHOULD use animated mascot, not bare `ProgressView`.** Eleven of the 34 code paths are `ProgressView()` with no Bamboo. `MascotBadge` already springs in on appear — feels alive even for sub-second loads. The Scan feature's `ScanLoadingView` is the exemplar (rotating mascot + cycling copy in a glass card); its pattern can be lifted to a shared `LoadingMascotView` once two more features need it.

5. **Consolidate inline error banners.** `ChatErrorBanner`, `PaywallView.errorBanner`, and `SettingsView.errorBanner` are three near-identical implementations of "amber/ember tinted RoundedRectangle with caption text." Lift to `Shared/Components/InlineErrorBanner.swift`. (Out of scope for this audit, but adjacent.) **Owner:** Agent C7 / design-system follow-up.

6. **Add a card-sized variant of `EmptyStateView`** (working name `EmptyStateView.compact` or `EmptyStateCard`). Three sub-card empty states (HerbProfile `EmptyRecipesCard`, HerbProfile `EmptyContraindicationsCard`, Paywall "Plans aren't available right now.") need a non-full-bleed flavor that drops `frame(maxHeight: .infinity)` and uses a smaller mascot (~64 pt). Today they're stuck rolling their own.

7. **Friendly error mapping** — `ChatThreadViewModel.friendly(_:)` and `PaywallViewModel.friendlyMessage(for:)` are the two shipping examples. **`HerbProfileErrorState` leaks `String(describing: error)` to the user**, which can surface raw Swift error type names. File a fix-up to apply the same pattern.

8. **Wire `VaultViewModel.errorMessage` into `VaultView`.** The view model populates the field on three paths but the view never reads it. Empty state migration is moot if the user never sees the failure.

## Open follow-ups

- **No `Bamboo/Confused` asset yet** — proposed for server-error states. Currently using `.sleeping` as a fallback in 6 recommended migrations (Scan error overlay, Home error, Onboarding failure, HerbProfile error, Chat list failure, Vault load failure). When `.confused` ships from `feat/assets-gen`, swap these.
- **No `Bamboo/Thinking` asset** — would replace the `.scanning` variant for *generic* loading (Home, HerbProfile, Chat). Lower priority since `.scanning` already feels active.
- **Missing CTA destinations** — recommended migrations for Vault empty (`"Scan a plant"`) and Scan permission empty (`"Open Settings"`) need a navigation contract from Phase B/C agents. Vault → Scan tab switching should route through whatever `RootNav` (Agent C1 / `feat/root-nav`) publishes; Settings deep link uses `UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)`.
- **Sub-card variant** of `EmptyStateView` is a design-system follow-up before HerbProfile sub-tabs and Paywall offerings can fully migrate (see cross-cutting #6).
- **Scan's `ScanLoadingView` and `QuotaReachedView`** are bespoke today but well-designed. After migration to `EmptyStateView`, the rotating-copy + glass-card chrome from `ScanLoadingView` is worth promoting into a shared `LoadingMascotView` — pending a second consumer.

## Self-check

Per-feature row counts that map to the summary table:

- Scan: 5 rows (2 already migrated, 2 migration, 1 acceptable). Sums into "already migrated: 2", "migration: 2".
- Recipes: 3 rows (1 migration, 2 acceptable). Sums into "migration: 1".
- Vault: 6 rows (3 migration, 3 acceptable-but-unrendered). Sums into "migration: 3".
- Home: 4 rows (2 migration, 2 acceptable-stub). Sums into "migration: 2".
- Onboarding: 4 rows (2 migration, 2 acceptable). Sums into "migration: 2".
- HerbProfile: 5 rows (2 full-bleed migration + 2 sub-card migration, 1 acceptable). Sums into "migration: 4".
- Chat: 8 rows (4 migration, 4 acceptable). Sums into "migration: 4".
- Paywall + Settings: 9 rows (1 migration + 1 sub-card-migration + 1 consolidation = 3 migration, 6 acceptable). Sums into "migration: 3".

Total rows: 5 + 3 + 6 + 4 + 4 + 5 + 8 + 9 = **44** distinct code paths inspected. Of those, 34 are empty/loading/error UI surfaces; 10 are inline `.isEmpty` guards in business logic that aren't UI. Of the 34 UI surfaces:

- Already migrated: **2** (matches summary)
- Bespoke illustration card with mascot/asset: **5** (matches summary)
- Bare error icon block: **6** (matches summary)
- Bare `ProgressView`: **11** (matches summary)
- Recommended for migration: **2 + 1 + 3 + 2 + 2 + 4 + 4 + 3 = 21** (call sites including 4 sub-card variants that need a new component)
- Acceptable as-is (after consolidation/asset gating): **34 - 21 - 2 = 11** full-screen surfaces + adjacent inline banners

Note: the summary table's "**17** recommended for migration" counts only the call sites that can migrate to the **existing** `EmptyStateView` API today. The remaining **4** sub-card sites are blocked on cross-cutting #6 (compact variant). 17 + 4 + 2 (already migrated) + ~11 (acceptable as-is for now) ≈ 34 UI surfaces.
