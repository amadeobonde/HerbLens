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
    @State private var selection: AppTab = .home
    @State private var showPaywallStub = false
    @State private var tier: SubscriptionTier = .free
    @State private var userDisplayName: String = "Guest"
    @State private var fabExpanded = false
    @State private var activeFlow: FABFlow?

    enum AppTab: Hashable { case home, recipes, vault, profile }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selection) {
                Tab("Home", systemImage: Theme.Icon.home, value: AppTab.home) {
                    HomeView(
                        onScanTap: { fabExpanded = true }
                    )
                }

                Tab("Recipes", systemImage: Theme.Icon.recipes, value: AppTab.recipes) {
                    RecipesHomeView()
                }

                Tab("Vault", systemImage: Theme.Icon.vault, value: AppTab.vault) {
                    VaultHomeView(herbs: [], brews: [])
                }

                Tab("Profile", systemImage: Theme.Icon.profile, value: AppTab.profile) {
                    ProfileView(
                        displayName: userDisplayName,
                        tier: tier,
                        showPaywall: triggerPaywallStub
                    )
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            .tabBarMinimizeBehavior(.onScrollDown)
            .tint(Theme.Color.sage)

            FABOverlay(isExpanded: $fabExpanded, activeFlow: $activeFlow)
        }
        .fullScreenCover(item: $activeFlow) { flow in
            switch flow {
            case .photoScan:
                ScanView(
                    onOpenVault: { @Sendable in Task { @MainActor in selection = .vault } },
                    onPaywall: { @Sendable in Task { @MainActor in showPaywallStub = true } }
                )
            case .barcodeScan:
                BarcodeScannerView()
            case .plantSearch:
                PlantSearchView()
            }
        }
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



#Preview("Tabs") {
    ContentView()
        .environment(\.dependencies, .mock)
}
