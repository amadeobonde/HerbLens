import Foundation
import Observation

/// View model for `HomeView`. Owns the load state and orchestrates parallel fetches
/// across plants, scans, and subscriptions. Stays `@MainActor` (the project default
/// per CLAUDE.md §10.1) so SwiftUI can read `state` synchronously without `await`.
@MainActor
@Observable
public final class HomeViewModel {
    public private(set) var state: HomeLoadState = .idle

    private let plants: any PlantsRepository
    private let scans: any ScansRepository
    private let subscriptions: any SubscriptionService
    private let auth: any AuthService

    /// Cap recents to a small horizontal row — scans table can grow large for power users.
    static let recentsLimit = 8

    public init(
        plants: any PlantsRepository,
        scans: any ScansRepository,
        subscriptions: any SubscriptionService,
        auth: any AuthService
    ) {
        self.plants = plants
        self.scans = scans
        self.subscriptions = subscriptions
        self.auth = auth
    }

    /// Initial load — flips into `.loading` then either `.loaded` or `.failed`.
    /// Safe to call multiple times; subsequent calls behave like `refresh`.
    public func load() async {
        state = .loading
        await fetch()
    }

    /// Pull-to-refresh entry point. Does NOT flip back through `.loading` so the
    /// existing feed stays visible behind the refresh control.
    public func refresh() async {
        await fetch()
    }

    private func fetch() async {
        do {
            let userID = await auth.currentUserID ?? ""

            async let featuredTask = plants.featured()
            async let collectionsTask = plants.highlightCollections()
            async let scansTask = scans.list(userID: userID, sort: .newest, filter: .none)
            async let tierTask = subscriptions.currentTier()

            let featured = try await featuredTask
            let collections = try await collectionsTask
            let allScans = try await scansTask
            let tier = await tierTask

            let recents = Array(allScans.prefix(Self.recentsLimit))
            let lookup = await loadPlantLookup(for: recents)

            let free = collections.filter { $0.accessTier == .free }
            let premium = collections.filter { $0.accessTier == .premium }

            state = .loaded(
                HomeData(
                    featured: featured,
                    freeCollections: free,
                    premiumCollections: premium,
                    recents: recents,
                    recentPlantsByID: lookup,
                    tier: tier
                )
            )
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Resolves `Plant` for each unique scanned plant ID. Sequential rather than
    /// `TaskGroup` because N ≤ `recentsLimit` (8); the parallelism overhead would
    /// outweigh the benefit, and order doesn't matter for a dictionary lookup.
    /// Tolerates per-plant lookup failures (deleted plant, transient error) — the
    /// recents row will hide the affected scan instead of failing the whole load.
    private func loadPlantLookup(for scans: [Scan]) async -> [String: Plant] {
        let uniqueIDs = Set(scans.map(\.identifiedPlantId))
        var lookup: [String: Plant] = [:]
        lookup.reserveCapacity(uniqueIDs.count)
        for id in uniqueIDs {
            if let plant = try? await plants.plant(id: id) {
                lookup[id] = plant
            }
        }
        return lookup
    }
}
