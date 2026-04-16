import Foundation

/// Feature-local fixtures for `HomeView` previews and tests. Provides 8 highlight
/// collections so the full v1 home layout is exercisable without modifying
/// `Services/Mock/SampleData.swift` (which is owned by Instance 2). Collection IDs
/// match the slugs `HomeCollectionCoverProvider` understands so the cover lookup
/// works end-to-end.
///
/// Note: this enum is intentionally NOT marked `nonisolated` so its `static let`
/// initializers default to `MainActor` and can call actor inits like
/// `MockServices.Scans()` synchronously. The conforming structs below ARE
/// `nonisolated` so they remain `Sendable` across actors.
enum HomePreviewData {
    /// All 8 v1 collections in display order. Mix of free + premium so previews
    /// cover both gating paths.
    static let collections: [HighlightCollection] = [
        HighlightCollection(
            id: "collection-sleep-aids",
            title: "Sleep Aids",
            subtitle: "Calming herbs to help you wind down naturally",
            coverImageUrl: "asset://SleepAids",
            plantIds: [SampleData.chamomile.id, SampleData.lavender.id],
            displayOrder: 0,
            accessTier: .free
        ),
        HighlightCollection(
            id: "collection-digestive-support",
            title: "Digestive Support",
            subtitle: "For everyday comfort after meals",
            coverImageUrl: "asset://DigestiveSupport",
            plantIds: [SampleData.peppermint.id, SampleData.ginger.id, SampleData.chamomile.id],
            displayOrder: 1,
            accessTier: .free
        ),
        HighlightCollection(
            id: "collection-stress-relief",
            title: "Stress Relief",
            subtitle: "Aromatic allies for nervous tension",
            coverImageUrl: "asset://StressRelief",
            plantIds: [SampleData.lavender.id, SampleData.chamomile.id],
            displayOrder: 2,
            accessTier: .free
        ),
        HighlightCollection(
            id: "collection-immunity",
            title: "Immunity",
            subtitle: "Cold-season support for resilient days",
            coverImageUrl: "asset://Immunity",
            plantIds: [SampleData.echinacea.id, SampleData.ginger.id],
            displayOrder: 3,
            accessTier: .free
        ),
        HighlightCollection(
            id: "collection-skin",
            title: "Skin",
            subtitle: "Soothing botanicals for clear, calm skin",
            coverImageUrl: "asset://Skin",
            plantIds: [SampleData.lavender.id, SampleData.chamomile.id],
            displayOrder: 4,
            accessTier: .premium
        ),
        HighlightCollection(
            id: "collection-energy",
            title: "Energy",
            subtitle: "Warming herbs for everyday vitality",
            coverImageUrl: "asset://Energy",
            plantIds: [SampleData.ginger.id, SampleData.peppermint.id],
            displayOrder: 5,
            accessTier: .premium
        ),
        HighlightCollection(
            id: "collection-focus",
            title: "Focus",
            subtitle: "Aromatic helpers for clear-headed work",
            coverImageUrl: "asset://Focus",
            plantIds: [SampleData.peppermint.id, SampleData.lavender.id],
            displayOrder: 6,
            accessTier: .premium
        ),
        HighlightCollection(
            id: "collection-womens-health",
            title: "Women's Health",
            subtitle: "Time-tested support across cycles and seasons",
            coverImageUrl: "asset://WomensHealth",
            plantIds: [SampleData.chamomile.id, SampleData.lavender.id, SampleData.echinacea.id],
            displayOrder: 7,
            accessTier: .premium
        ),
    ]

    /// Wrapper repository serving the expanded 8-collection set. Delegates every
    /// other call to the underlying `MockServices.Plants`, so featured/search/etc.
    /// behave identically to the standard mock.
    nonisolated struct CollectionsRepo: PlantsRepository {
        let inner: MockServices.Plants

        nonisolated init() {
            self.inner = MockServices.Plants()
        }

        func featured() async throws -> [Plant] { try await inner.featured() }
        func plant(id: String) async throws -> Plant { try await inner.plant(id: id) }
        func search(query: String) async throws -> [Plant] { try await inner.search(query: query) }
        func healthScore(for plantID: String, userID: String) async throws -> HealthScore {
            try await inner.healthScore(for: plantID, userID: userID)
        }
        func highlightCollections() async throws -> [HighlightCollection] {
            HomePreviewData.collections
        }
    }

    /// Always-premium subscriptions stub. Lives here (not in `Services/Mock/`) so
    /// the Home feature stays self-contained — Instance 2 owns Services/.
    nonisolated struct PremiumSubscriptions: SubscriptionService {
        nonisolated init() {}
        func currentTier() async -> SubscriptionTier { .premium }
        func offerings() async throws -> [Offering] { SampleData.offerings }
        func purchase(packageID: String) async throws -> SubscriptionTier { .premium }
        func restore() async throws -> SubscriptionTier { .premium }
    }

    /// `AppDependencies` variant wired to the 8-collection repo. Use in `#Preview` blocks.
    static let dependencies: AppDependencies = AppDependencies(
        auth: MockServices.Auth(),
        plants: CollectionsRepo(),
        scans: MockServices.Scans(),
        chat: MockServices.Chat(),
        subscriptions: MockServices.Subscriptions(),
        healthProfile: MockServices.HealthProfileRepo()
    )

    /// Premium-tier variant — `currentTier()` returns `.premium` immediately so
    /// previews exercise the "Curated for you" section without first running
    /// `purchase()` on the subscriptions actor.
    static let premiumDependencies: AppDependencies = AppDependencies(
        auth: MockServices.Auth(),
        plants: CollectionsRepo(),
        scans: MockServices.Scans(),
        chat: MockServices.Chat(),
        subscriptions: PremiumSubscriptions(),
        healthProfile: MockServices.HealthProfileRepo()
    )
}
