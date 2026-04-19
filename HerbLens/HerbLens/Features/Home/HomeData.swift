import Foundation

/// Snapshot of everything `HomeView` needs to render in a single layout pass.
/// Built by `HomeViewModel.load()` from the injected repositories — never mutated
/// in place, replaced atomically on refresh so the view never sees a half-loaded state.
public nonisolated struct HomeData: Sendable, Equatable {
    public let featured: [Plant]
    public let freeCollections: [HighlightCollection]
    public let premiumCollections: [HighlightCollection]
    public let recents: [Scan]
    /// Lookup so the recents row can render plant name/thumbnail without a second fetch.
    public let recentPlantsByID: [String: Plant]
    public let tier: SubscriptionTier
    public let totalScanCount: Int

    public init(
        featured: [Plant],
        freeCollections: [HighlightCollection],
        premiumCollections: [HighlightCollection],
        recents: [Scan],
        recentPlantsByID: [String: Plant],
        tier: SubscriptionTier,
        totalScanCount: Int = 0
    ) {
        self.featured = featured
        self.freeCollections = freeCollections
        self.premiumCollections = premiumCollections
        self.recents = recents
        self.recentPlantsByID = recentPlantsByID
        self.tier = tier
        self.totalScanCount = totalScanCount
    }
}
