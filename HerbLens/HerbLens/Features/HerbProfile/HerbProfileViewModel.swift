import Foundation
import Observation

/// Owns load + interaction state for the HerbProfile screen. Kept on the MainActor (the
/// project default under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`) so views can read
/// state without hopping actors.
@MainActor
@Observable
final class HerbProfileViewModel {
    let plantID: String
    private let plants: any PlantsRepository
    private let subscriptions: any SubscriptionService
    private let auth: any AuthService

    private(set) var state: HerbProfileLoadState = .idle
    var selectedTab: HerbTab = .uses
    var isBreakdownExpanded: Bool = false

    init(
        plantID: String,
        plants: any PlantsRepository,
        subscriptions: any SubscriptionService,
        auth: any AuthService
    ) {
        self.plantID = plantID
        self.plants = plants
        self.subscriptions = subscriptions
        self.auth = auth
    }

    /// Fetch the plant + its personalized health score + the current tier in parallel.
    /// Idempotent on `.loaded`: callers may re-invoke from `.task` without risking duplicate
    /// work once the state has settled. A failure transitions to `.failed` so the view can
    /// offer a retry affordance.
    func load() async {
        if case .loaded = state { return }
        state = .loading

        do {
            let userID = await auth.currentUserID ?? "preview-user"

            async let plantFetch = plants.plant(id: plantID)
            async let scoreFetch = plants.healthScore(for: plantID, userID: userID)
            async let tierFetch = subscriptions.currentTier()

            let plant = try await plantFetch
            let score = try await scoreFetch
            let tier = await tierFetch

            state = .loaded(HerbProfilePayload(plant: plant, healthScore: score, tier: tier))
        } catch {
            state = .failed(error)
        }
    }

    /// Force a reload (e.g. from a retry button). Skips the "already loaded" guard.
    func retry() async {
        state = .idle
        await load()
    }

    func toggleBreakdown() {
        isBreakdownExpanded.toggle()
    }
}
