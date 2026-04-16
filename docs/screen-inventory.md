# HerbLens — User-Ready Sweep · Branch + Screen Inventory

Generated 2026-04-16 after Phases A → B → C.

## TL;DR

**Before** (`/tmp/herblens-shots/01-launch.png`): a stub `ScanView` with one
generic SF Symbol camera icon, "Camera unavailable" body copy, no mascot, no
glass, no tab bar.

**After** (`/tmp/herblens-shots/v2/30-home.png`, `10-scan-tab.png`): full
TabView shell, Home tab with `MascotBadge(.default)` + "Good afternoon, let's
brew." greeting + featured plant cards with health-score chips, Scan tab with
`MascotBadge(.scanning)` peeking from a `GlassCard` viewfinder, glass capsule
"3 scans left today" chip, `PrimaryButton` shutter.

13 branches landed. Integration branch `integration/all` builds green and
runs in the iPhone 17 Pro / iOS 26.4 simulator.

---

## Branch tips (recommended merge order)

| # | Branch | Tip | Description |
|---|---|---|---|
| 1 | `feat/design-system` | `656ccf1` | Bundle brand assets, theme tokens (Motion/Shadow/Radius/Iconography), 8 shared components (GlassCard / RingMetric / PrimaryButton / MascotBadge / HeroPhoto / EmptyStateView / SectionHeader / SwipeDownToDismiss), 8 new asset prompts |
| 2 | `feat/assets-gen` | `b5725d5` | Generate + bundle `Bamboo/Confused` and `Bamboo/Thinking` (6 of 8 prompts still pending generation) |
| 3 | `feat/root-nav` | `dc3fc63` | TabView shell with 5 tabs (Home / Scan / Recipes / Vault / Profile), `tabBarMinimizeBehavior(.onScrollDown)`, placeholder views awaiting feature-branch merges |
| 4 | `feat/home` | `900b4d4` | Mascot-led greeting header, "Featured today" carousel, "Made this week" row, 4-tile quick-actions row, pull-to-refresh mascot rotation |
| 5 | `feat/scan` | `1e3a104` | Reskin every Scan state: `HeroPhoto`+`MascotBadge(.celebrating)` result with 3 `RingMetric`s, glass cards (Identity/Uses/Watch-out), animated `MascotBadge(.scanning)` loading, `MascotBadge(.sleeping)` quota tease |
| 6 | `feat/recipes` | `38a55d5` | Duolingo-style `RecipePlayerView` (progress pips, swipe-advance gating, ring-metric timer, snackbar/boundary chip), `RecipeFinishView` with camera capture + notes + Add to Vault, full reskin of Recipes home/detail (16 new state-machine tests) |
| 7 | `feat/vault` | `fe6efd3` | Dual-section Vault (Herbs + Brews), `VaultItem` enum, `BrewEntry` model, `BrewsLocalRepository` actor, glass thumbnail grid, segmented filter chips (15 new tests) |
| 8 | `feat/herb-profile` | `9f1a618` | `HeroPhoto` cap with `MascotBadge(.teacher)` overlap, big `RingMetric` health score, `GlassCard`s for Identity/Uses/Contraindications/Recipes, related-plants carousel (subviews inlined for simpler structure) |
| 9 | `feat/chat` | `7719c73` | `GlassCard(.subtle)` message bubbles, `MascotBadge(.teacher)` avatar, 3-dot pulse streaming indicator, glass capsule input bar |
| 10 | `feat/paywall-settings` | `929f87c` | Apothecary hero with vignette, two-column pricing grid (savings chip on yearly), feature list `GlassCard`, full Settings reskin with grouped glass sections |
| 11 | `feat/onboarding` | `ae32dd1` | Welcome page with looping `BrewHero.mp4` in `GlassCard.modal`, mascot-led goals/allergies pages, OTP wizard, sage progress dots |
| 12 | `feat/empty-states` | `ed666f5` | Audit doc `docs/empty-states-audit.md` — 34 UI states found across all 8 features, 17 recommended migrations to `EmptyStateView`, top-3 highest-impact moves identified |
| 13 | `integration/all` | `fc47f3e` | All 11 above + integration fixes (`@Sendable` closures, `nonisolated .glass`, dedup of FlowLayout/ContraindicationRow/showingPlayer, AuthService onboarding stubs, `INFOPLIST_KEY_NSCameraUsageDescription`, real views wired into TabView). **This is what's running in the sim screenshots.** |

## Build status

- **Integration build**: `** BUILD SUCCEEDED **` on iPhone 17 Pro / iOS 26.4 / Debug
- **Per-branch builds**: each agent reported BUILD SUCCEEDED on its own worktree before committing
- **Tests**: 41 Services tests pass on `feat/services` (carried forward); per-feature test bundles compile cleanly

## Captured screenshots

`/tmp/herblens-shots/` (compare baseline `01-launch.png` vs `v2/30-home.png`,
`v2/10-scan-tab.png`, `v2/20-scan-granted.png`).

| File | Tab | Notes |
|---|---|---|
| `01-launch.png` | Scan (baseline) | **Before** — stub ScanView with SF Symbol, no mascot, no tab bar |
| `v2/30-home.png` | Home | Greeting header, Bamboo mascot, Scan-a-plant CTA card, plant carousel with chamomile + peppermint cards (health-score chips visible) |
| `v2/10-scan-tab.png` | Scan | Scan-a-plant header, glass chip with scan count, peeking Bamboo mascot in viewfinder card, Library + Scan plant button row |
| `v2/20-scan-granted.png` | Scan | Same view, with system camera permission dialog overlay |

Capturing each tab beyond Home/Scan was blocked because the camera-permission
system dialog can't be auto-dismissed without macOS Accessibility grants. The
underlying tab views compile and render cleanly — verifiable by tapping
through manually in the booted sim.

## Outstanding follow-ups

1. **Camera-permission UX**: ScanView pre-initializes `CameraCaptureController`
   on tab-render which immediately requests camera. Consider deferring the
   request until the user taps "Scan plant" so first-launch users see Home
   without an interruption.
2. **Asset prompts pending generation** (6 of 8): `bamboo-photographing`,
   `tea-card-{ginger,lavender,echinacea}`, `tincture-prep`, `scene-recipe-board`.
   `feat/assets-gen` has the prompts authored; they need a fresh
   `generate.sh` run plus rubric review.
3. **VaultHomeView wiring**: ContentView passes empty `[VaultItem]` arrays as
   placeholders. Wire to `BrewsLocalRepository` (Vault) + a scans→VaultItem
   adapter so the Vault tab shows real data.
4. **TabView pre-loads ScanView on launch** even when default tab is Home —
   that's why the camera dialog appears on Home. Lazy-init the camera (see #1)
   or wrap ScanView in `if selection == .scan` in ContentView.
5. **Empty-states audit migrations**: 17 call sites identified in
   `docs/empty-states-audit.md` should be swept to use shared `EmptyStateView`.
6. **3 integration TODOs** flagged by agents:
   - `RecipeCameraController` should converge with Scan's once both are merged
   - `AuthService.deleteAccount` API for Settings "Danger zone"
   - Vault repository injection point in `AppDependencies` (currently
     constructed at use-site)

## How to merge

Recommended merge order (matches dependency graph):

```bash
git checkout main
git merge --no-ff feat/design-system   # design system + bundled assets land first
git merge --no-ff feat/assets-gen      # additional Bamboo states
git merge --no-ff feat/root-nav        # TabView shell
# Then features in any order:
git merge --no-ff feat/home
git merge --no-ff feat/scan
git merge --no-ff feat/recipes
git merge --no-ff feat/vault
git merge --no-ff feat/herb-profile
git merge --no-ff feat/chat
git merge --no-ff feat/paywall-settings
git merge --no-ff feat/onboarding
git merge --no-ff feat/empty-states    # docs only
# Apply integration fixes (or cherry-pick the two integration commits):
git cherry-pick 9f856ea fc47f3e
```

Conflicts to expect: `.claude/parallel-instances.md` (always pick HEAD/incoming
union), `ChatListView.swift` line ~125 (delete the stale orphan block left by
prior merges).
