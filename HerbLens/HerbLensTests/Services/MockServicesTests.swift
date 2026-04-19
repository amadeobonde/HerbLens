import Foundation
import Testing
@testable import HerbLens

/// Sanity tests for the mock implementations — they're the backbone of every Preview and
/// downstream feature test, so we pin behavior here.
@Suite("Mock services")
struct MockServicesTests {
    @Test("seed contains all five canonical plants")
    func seedHasFivePlants() {
        let names = SampleData.plants.map(\.commonName).sorted()
        #expect(names == ["Chamomile", "Echinacea", "Ginger", "Lavender", "Peppermint"])
    }

    @Test("featured() returns only plants marked featured")
    func featuredOnlyReturnsFeatured() async throws {
        let repo = MockServices.Plants()
        let featured = try await repo.featured()
        let allFeatured = featured.allSatisfy { $0.featured }
        #expect(allFeatured)
        #expect(featured.count >= 3) // chamomile, peppermint, ginger
    }

    @Test("search finds by alternate name and tag")
    func searchMatchesAliases() async throws {
        let repo = MockServices.Plants()
        let byAlias = try await repo.search(query: "matricaria")
        #expect(byAlias.contains(where: { $0.commonName == "Chamomile" }))

        let byTag = try await repo.search(query: "calming")
        #expect(byTag.contains(where: { $0.commonName == "Chamomile" }))
        #expect(byTag.contains(where: { $0.commonName == "Lavender" }))
    }

    @Test("toggleFavorite flips the stored value")
    func toggleFavorite() async throws {
        let repo = await MockServices.Scans()
        let before = try await repo.list(userID: SampleData.userID, sort: .newest, filter: .none)
        guard let first = before.first else {
            Issue.record("expected seed scan")
            return
        }
        try await repo.toggleFavorite(scanID: first.id)
        let after = try await repo.list(userID: SampleData.userID, sort: .newest, filter: .none)
        let flipped = after.first(where: { $0.id == first.id })
        #expect(flipped?.isFavorited == !first.isFavorited)
    }

    @Test("chat mock streams word-by-word and terminates")
    func chatStreams() async throws {
        let repo = MockServices.Chat()
        var assembled = ""
        for try await chunk in repo.send(message: "hi", to: "c1") {
            assembled += chunk
        }
        #expect(!assembled.isEmpty)
    }
}
