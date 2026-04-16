import SwiftUI

/// Root view of the Home tab. Hosts a `NavigationStack` with a typed path so the
/// destination logic stays inside this feature — Instance 6 (HerbProfile) swaps in
/// its real view at the `navigationDestination` site once it lands.
public struct HomeView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: HomeViewModel?
    @State private var path: [HomeRoute] = []

    public init() {}

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
            Image(systemName: "exclamationmark.triangle.fill")
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
            Button {
                Task { await viewModel?.load() }
            } label: {
                Text("Retry")
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.bone)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Theme.Color.forest, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.xl)
    }

    @ViewBuilder
    private func loadedView(_ data: HomeData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                ScanCTAButton {
                    // Scan flow lives in Instance 5. Wiring requires a destination
                    // type owned by Scan — intentionally out of scope here.
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.lg)

                if !data.featured.isEmpty {
                    FeaturedPlantsCarousel(plants: data.featured) { plant in
                        path.append(.plant(id: plant.id))
                    }
                }

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
