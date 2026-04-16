import Foundation

/// Bundle of values the HerbProfile screen needs after a successful load.
public nonisolated struct HerbProfilePayload: Sendable, Hashable {
    public let plant: Plant
    public let healthScore: HealthScore
    public let tier: SubscriptionTier

    public init(plant: Plant, healthScore: HealthScore, tier: SubscriptionTier) {
        self.plant = plant
        self.healthScore = healthScore
        self.tier = tier
    }
}

/// Screen-level load machine. `failed` wraps an Error (non-Hashable), so `HerbProfileLoadState`
/// itself is only `Sendable` — not Equatable. Tests assert on `.loaded(payload).payload`
/// or on `.failed(error).errorDescription`, which sidesteps the need for equality.
public enum HerbProfileLoadState: Sendable {
    case idle
    case loading
    case loaded(HerbProfilePayload)
    case failed(Error)

    public var payload: HerbProfilePayload? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    public var errorDescription: String? {
        if case .failed(let error) = self { return String(describing: error) }
        return nil
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
