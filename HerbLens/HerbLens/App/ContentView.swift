import SwiftUI

/// Root TabView shell for HerbLens.
///
/// Each tab currently shows an `EmptyStateView` placeholder that will be swapped out
/// when the corresponding Phase B feature branch merges:
///
///   * Home     — `feat/home`          (Instance 4)
///   * Scan     — `feat/scan`          (Instance 5, already active)
///   * Recipes  — `feat/recipes`       (Instance 7)
///   * Vault    — `feat/vault`         (Instance 8)
///   * Profile  — `feat/paywall-settings` (Instance 10) + auth/profile polish
///
/// Each instance owns its tab's feature folder and will replace *only* the matching
/// placeholder here on merge. Nothing else in this file should change on those merges —
/// keeps the nav shell a stable integration surface.
struct ContentView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var selection: AppTab = .scan
    @State private var showPaywallStub = false
    @State private var tier: SubscriptionTier = .free
    @State private var userDisplayName: String = "Guest"

    /// Top-level tab identity. Distinct from SwiftUI's `Tab` builder type.
    enum AppTab: Hashable { case home, scan, recipes, vault, profile }

    var body: some View {
        // Tab order is deliberate: Scan sits in the center (3rd of 5) because
        // identify-a-plant is the primary use case per the product brief. Thumb
        // hit-zone on a phone naturally falls under the center tab. The app
        // launches directly on Scan (see `selection` default) so first-time
        // users can take a photo without a single tap.
        TabView(selection: $selection) {
            Tab("Home", systemImage: Theme.Icon.home, value: AppTab.home) {
                HomeView(
                    onScanTap: { [self] in selection = .scan },
                    onRecipesTap: { [self] in selection = .recipes },
                    onVaultTap: { [self] in selection = .vault },
                    onChatTap: { [self] in showPaywallStub = true }
                )
            }

            Tab("Recipes", systemImage: Theme.Icon.recipes, value: AppTab.recipes) {
                RecipesHomeView()
            }

            Tab("Scan", systemImage: Theme.Icon.scan, value: AppTab.scan) {
                ScanView(
                    onOpenVault: { @Sendable in Task { @MainActor in selection = .vault } },
                    onPaywall: { @Sendable in Task { @MainActor in showPaywallStub = true } }
                )
            }

            Tab("Vault", systemImage: Theme.Icon.vault, value: AppTab.vault) {
                VaultHomeView(herbs: [], brews: [])
            }

            Tab("Profile", systemImage: Theme.Icon.profile, value: AppTab.profile) {
                ProfileTabPlaceholder(
                    displayName: userDisplayName,
                    tier: tier,
                    showPaywall: triggerPaywallStub
                )
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(Theme.Color.sage)
        .task {
            tier = await dependencies.subscriptions.currentTier()
            userDisplayName = await resolveDisplayName()
        }
        .alert("Premium feature", isPresented: $showPaywallStub) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Paywall lands when feat/paywall-settings merges.")
        }
    }

    private func triggerPaywallStub() {
        showPaywallStub = true
    }

    /// Best-effort display-name resolution. Swallows errors so the tab still renders.
    private func resolveDisplayName() async -> String {
        // The mock AuthService returns `SampleData.userProfile` on sign-in, but the
        // live path exposes only `currentUserID`. When the full profile API lands we
        // can swap this for a direct lookup. For now we surface a stable preview name.
        guard (await dependencies.auth.currentUserID) != nil else { return "Guest" }
        return "Preview User"
    }
}

// MARK: - Tab placeholders
//
// Each placeholder is a drop-in stand-in for the real feature view. When a feature
// branch merges, replace the `body` of the matching placeholder with a single
// `<Feature>View()` call (or delete the struct and reference the real view inline
// in the `TabView` above).

private struct HomeTabPlaceholder: View {
    let showPaywall: () -> Void

    var body: some View {
        EmptyStateView(
            mascot: .default,
            title: "Home coming soon",
            subtitle: "Lands when feat/home merges.",
            ctaTitle: nil,
            action: nil
        )
        .background(Theme.Color.background.ignoresSafeArea())
    }
}

private struct ScanTabPlaceholder: View {
    let showPaywall: () -> Void

    var body: some View {
        EmptyStateView(
            mascot: .scanning,
            title: "Scan coming soon",
            subtitle: "Lands when feat/scan merges.",
            ctaTitle: nil,
            action: nil
        )
        .background(Theme.Color.background.ignoresSafeArea())
    }
}

private struct RecipesTabPlaceholder: View {
    let showPaywall: () -> Void

    var body: some View {
        EmptyStateView(
            mascot: .brewing,
            title: "Recipes coming soon",
            subtitle: "Lands when feat/recipes merges.",
            ctaTitle: nil,
            action: nil
        )
        .background(Theme.Color.background.ignoresSafeArea())
    }
}

private struct VaultTabPlaceholder: View {
    let showPaywall: () -> Void

    var body: some View {
        EmptyStateView(
            mascot: .teacher,
            title: "Vault coming soon",
            subtitle: "Lands when feat/vault merges.",
            ctaTitle: nil,
            action: nil
        )
        .background(Theme.Color.background.ignoresSafeArea())
    }
}

private struct ProfileTabPlaceholder: View {
    let displayName: String
    let tier: SubscriptionTier
    let showPaywall: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.xs) {
                Text(displayName)
                    .font(Theme.Font.display)
                    .foregroundStyle(Theme.Color.textPrimary)

                TierChipStub(tier: tier)
            }
            .padding(.top, Theme.Spacing.xl)

            EmptyStateView(
                mascot: .sleeping,
                title: "Profile coming soon",
                subtitle: "Lands when feat/paywall-settings merges.",
                ctaTitle: nil,
                action: nil
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Color.background.ignoresSafeArea())
    }
}

/// Lightweight tier badge — replaced by the real chip from `feat/paywall-settings`
/// once that branch merges.
private struct TierChipStub: View {
    let tier: SubscriptionTier

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Image(systemName: Theme.Icon.paywall)
                .font(.caption)
            Text(label)
                .font(Theme.Font.caption.weight(.semibold))
                .textCase(.uppercase)
        }
        .padding(.vertical, Theme.Spacing.xxs)
        .padding(.horizontal, Theme.Spacing.sm)
        .foregroundStyle(foreground)
        .background(
            Capsule()
                .fill(background)
        )
    }

    private var label: String {
        switch tier {
        case .free: return "Free"
        case .premium: return "Pro"
        }
    }

    private var foreground: SwiftUI.Color {
        switch tier {
        case .free: return Theme.Color.textSecondary
        case .premium: return Theme.Color.bone
        }
    }

    private var background: SwiftUI.Color {
        switch tier {
        case .free: return Theme.Color.sage.opacity(0.15)
        case .premium: return Theme.Color.amber
        }
    }
}

#Preview("Tabs") {
    ContentView()
        .environment(\.dependencies, .mock)
}
