import SwiftUI

/// Root view of the Home tab. Hosts a `NavigationStack` with a typed path so the
/// destination logic stays inside this feature — Instance 6 (HerbProfile) swaps in
/// its real view at the `navigationDestination` site once it lands.
public struct HomeView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: HomeViewModel?
    @State private var path: [HomeRoute] = []
    /// Total mascot rotation in degrees. Bumped by 360 on each pull-to-refresh so the
    /// header Bamboo spins one full turn via `Theme.Motion.snappy`.
    @State private var mascotRotation: Double = 0

    /// Navigation closures so ContentView can drive tab switches when a Home button
    /// is tapped. Every closure is optional for preview/test ergonomics.
    public let onScanTap: (@Sendable @MainActor () -> Void)?
    public let onRecipesTap: (@Sendable @MainActor () -> Void)?
    public let onVaultTap: (@Sendable @MainActor () -> Void)?
    public let onChatTap: (@Sendable @MainActor () -> Void)?

    public init(
        onScanTap: (@Sendable @MainActor () -> Void)? = nil,
        onRecipesTap: (@Sendable @MainActor () -> Void)? = nil,
        onVaultTap: (@Sendable @MainActor () -> Void)? = nil,
        onChatTap: (@Sendable @MainActor () -> Void)? = nil
    ) {
        self.onScanTap = onScanTap
        self.onRecipesTap = onRecipesTap
        self.onVaultTap = onVaultTap
        self.onChatTap = onChatTap
    }

    public var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("HerbLens")
                .navigationBarTitleDisplayMode(.inline)
                .background(Theme.Color.background.ignoresSafeArea())
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .plant(let id):
                        PendingPlantDetailDestination(plantID: id)
                    }
                }
        }
        .task {
            if viewModel == nil {
                viewModel = makeViewModel()
                await viewModel?.load()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Re-sync the subscription tier when returning from the paywall
            // without a full app relaunch. SubscriptionService doesn't expose
            // an AsyncStream yet — pending request to Instance 1 logged.
            if phase == .active {
                Task { await viewModel?.refresh() }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel?.state ?? .idle {
        case .idle, .loading:
            loadingView
        case .loaded(let data):
            loadedView(data)
        case .failed(let message):
            errorView(message: message)
        }
    }

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            ProgressView()
            Text("Gathering today's herbs…")
                .font(Theme.Font.callout)
                .foregroundStyle(Theme.Color.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: Theme.Icon.error)
                .font(.system(size: 32))
                .foregroundStyle(Theme.Color.ember)
            Text("Couldn't load Home")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            Text(message)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)
            PrimaryButton("Retry") {
                Task { @MainActor in await viewModel?.load() }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.xl)
    }

    @ViewBuilder
    private func loadedView(_ data: HomeData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                HomeGreetingHeader(rotation: mascotRotation)
                    .padding(.top, Theme.Spacing.xs)

                ScanCTAButton {
                    onScanTap?()
                }
                .padding(.horizontal, Theme.Spacing.md)

                HomeQuickActionsRow(
                    onScan: { onScanTap?() },
                    onRecipes: { onRecipesTap?() },
                    onVault: { onVaultTap?() },
                    onChat: { onChatTap?() }
                )

                if !data.featured.isEmpty {
                    // Rotate daily so the "Featured today" strip feels fresh —
                    // deterministic per UTC calendar day, no server call needed.
                    FeaturedPlantsCarousel(plants: DailyRotation.rotated(data.featured)) { plant in
                        path.append(.plant(id: plant.id))
                    }
                }

                MadeThisWeekRow(onBrowseRecipes: { @Sendable in
                    // Recipes tab routing belongs to Instance 7. Placeholder closure for now.
                })

                RecentlyScannedRow(
                    recents: data.recents,
                    plantsByID: data.recentPlantsByID
                ) { plant in
                    path.append(.plant(id: plant.id))
                }

                if data.tier == .premium && !data.premiumCollections.isEmpty {
                    CuratedForYouSection(
                        collections: data.premiumCollections,
                        plantsByID: collectionLookup(data: data)
                    ) { plant in
                        path.append(.plant(id: plant.id))
                    }
                }

                ForEach(data.freeCollections) { collection in
                    HomeHighlightCollectionRow(
                        collection: collection,
                        plants: collectionPlants(collection, lookup: collectionLookup(data: data))
                    ) { plant in
                        path.append(.plant(id: plant.id))
                    }
                }

                Color.clear.frame(height: Theme.Spacing.xl)
            }
        }
        .refreshable {
            withAnimation(Theme.Motion.snappy) {
                mascotRotation += 360
            }
            await viewModel?.refresh()
        }
    }

    /// Plants reachable to the Home view come from the union of featured + recents
    /// — anything else would require a second per-collection fetch and would slow
    /// the initial render. Cards we can't render are silently skipped.
    private func collectionLookup(data: HomeData) -> [String: Plant] {
        var lookup = data.recentPlantsByID
        for plant in data.featured { lookup[plant.id] = plant }
        return lookup
    }

    private func collectionPlants(_ collection: HighlightCollection, lookup: [String: Plant]) -> [Plant] {
        collection.plantIds.compactMap { lookup[$0] }
    }

    private func makeViewModel() -> HomeViewModel {
        HomeViewModel(
            plants: dependencies.plants,
            scans: dependencies.scans,
            subscriptions: dependencies.subscriptions,
            auth: dependencies.auth
        )
    }
}

#Preview("Free tier") {
    HomeView()
        .environment(\.dependencies, HomePreviewData.dependencies)
}

#Preview("Premium tier") {
    HomeView()
        .environment(\.dependencies, HomePreviewData.premiumDependencies)
}
