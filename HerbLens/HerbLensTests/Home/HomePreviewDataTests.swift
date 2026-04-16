import Foundation
import Testing
@testable import HerbLens

/// Sanity checks for the feature-local fixtures. If these break, every preview and
/// every `HomeViewModel` test breaks too — pin behavior here for fast diagnosis.
@Suite("HomePreviewData")
struct HomePreviewDataTests {
    @Test("ships exactly 8 collections in display order")
    func eightCollectionsInOrder() {
        let collections = HomePreviewData.collections
        #expect(collections.count == 8)
        let orders = collections.map(\.displayOrder)
        #expect(orders == Array(0..<8))
    }

    @Test("every referenced plant ID resolves against SampleData.plants")
    func plantIdsResolve() {
        let knownIDs = Set(SampleData.plants.map(\.id))
        for collection in HomePreviewData.collections {
            for id in collection.plantIds {
                #expect(knownIDs.contains(id), "unknown plant ID \(id) in \(collection.title)")
            }
        }
    }

    @Test("collection IDs match the slugs HomeCollectionCoverProvider knows about")
    func slugsMatchCoverProvider() {
        let knownSlugs = Set(HomeCollectionCoverProvider.assetNamesBySlug.keys)
        for collection in HomePreviewData.collections {
            #expect(knownSlugs.contains(collection.id), "no asset mapping for \(collection.id)")
        }
    }

    @Test("mix of free and premium collections so both gating paths are exercised")
    func mixOfFreeAndPremium() {
        let collections = HomePreviewData.collections
        let free = collections.filter { $0.accessTier == .free }
        let premium = collections.filter { $0.accessTier == .premium }
        #expect(!free.isEmpty)
        #expect(!premium.isEmpty)
    }

    @Test("CollectionsRepo.highlightCollections() returns the 8-collection set")
    func collectionsRepoServesEight() async throws {
        let repo = HomePreviewData.CollectionsRepo()
        let collections = try await repo.highlightCollections()
        #expect(collections.count == 8)
    }

    @Test("CollectionsRepo delegates featured() to the underlying mock")
    func collectionsRepoDelegatesFeatured() async throws {
        let repo = HomePreviewData.CollectionsRepo()
        let featured = try await repo.featured()
        let viaMock = try await MockServices.Plants().featured()
        #expect(featured.map(\.id) == viaMock.map(\.id))
    }

    @Test("PremiumSubscriptions returns .premium without needing a purchase call")
    func premiumSubscriptionsAlwaysPremium() async {
        let subs = HomePreviewData.PremiumSubscriptions()
        let tier = await subs.currentTier()
        #expect(tier == .premium)
    }

    @Test("HomeCollectionCoverProvider falls back to SF Symbol for unknown slug")
    func coverProviderFallback() {
        let symbol = HomeCollectionCoverProvider.fallbackSymbol(for: "collection-unknown")
        #expect(symbol == "leaf.circle.fill")
    }

    @Test("HomeCollectionCoverProvider has a themed fallback for every known slug")
    func everyKnownSlugHasThemedFallback() {
        for slug in HomeCollectionCoverProvider.assetNamesBySlug.keys {
            let symbol = HomeCollectionCoverProvider.fallbackSymbol(for: slug)
            #expect(symbol != "leaf.circle.fill", "slug \(slug) is using the generic fallback")
        }
    }
}
