import Foundation
@testable import HerbLens

/// Shared canned plants for test fixtures, kept out of the live `SampleData` so mutations
/// here don't leak into Previews.
enum TestPlants {
    static let chamomile = SampleData.chamomile
    static let peppermint = SampleData.peppermint
    static let all = SampleData.plants
}

/// A PlantsRepository that serves pre-canned data — used by the Scans identify test so we
/// can verify the plant-name → Plant resolution logic without touching Postgres.
struct InMemoryPlantsRepository: PlantsRepository {
    let catalog: [Plant]

    func featured() async throws -> [Plant] { catalog.filter(\.featured) }
    func plant(id: String) async throws -> Plant {
        guard let p = catalog.first(where: { $0.id == id }) else {
            throw NSError(domain: "test", code: 404)
        }
        return p
    }
    func search(query: String) async throws -> [Plant] {
        let q = query.lowercased()
        return catalog.filter { $0.commonName.lowercased().contains(q) }
    }
    func healthScore(for plantID: String, userID: String) async throws -> HealthScore {
        try await plant(id: plantID).healthScore
    }
    func highlightCollections() async throws -> [HighlightCollection] { [] }
}

/// Always-premium subscription stub so tests that aren't about the quota guard don't
/// accidentally trip it.
struct AlwaysPremiumSubscriptionService: SubscriptionService {
    func currentTier() async -> SubscriptionTier { .premium }
    func offerings() async throws -> [Offering] { [] }
    func purchase(packageID: String) async throws -> SubscriptionTier { .premium }
    func restore() async throws -> SubscriptionTier { .premium }
}
