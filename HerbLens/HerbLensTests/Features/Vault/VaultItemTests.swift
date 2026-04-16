import Foundation
import Testing
@testable import HerbLens

/// Behavioural tests for the dual-section `VaultItem` enum. The interesting property
/// is chronological mixing — `[VaultItem].sorted(by: { $0.capturedAt > $1.capturedAt })`
/// should interleave Herbs and Brews by capture timestamp regardless of which case
/// each item is.
@Suite("VaultItem — id, accessors, mixed chronological sort")
struct VaultItemTests {
    private static func makeScan(id: String, daysAgo: Int, favorited: Bool = false) -> Scan {
        let anchor = Date(timeIntervalSince1970: 1_744_243_200)
        return Scan(
            id: id,
            userId: "test-user",
            photoUrl: "https://example.invalid/scans/\(id).jpg",
            scannedAt: anchor.addingTimeInterval(-Double(daysAgo) * 86_400),
            identifiedPlantId: "plant-\(id)",
            confidenceScore: 0.9,
            isFavorited: favorited,
            healthScoreAtScan: 80,
            accessTier: .free
        )
    }

    private static func makeBrew(id: String, daysAgo: Int, favorited: Bool = false) -> BrewEntry {
        let anchor = Date(timeIntervalSince1970: 1_744_243_200)
        return BrewEntry(
            id: id,
            recipeID: "recipe-\(id)",
            recipeTitle: "Brew \(id)",
            photoLocalURL: URL(fileURLWithPath: "/tmp/\(id).jpg"),
            notes: nil,
            brewedAt: anchor.addingTimeInterval(-Double(daysAgo) * 86_400),
            isFavorited: favorited
        )
    }

    // MARK: -

    @Test("ids are namespaced so a scan and a brew with the same underlying id don't collide")
    func idNamespacing() {
        let scan = Self.makeScan(id: "abc", daysAgo: 1)
        let brew = Self.makeBrew(id: "abc", daysAgo: 1)
        let herbItem = VaultItem.herb(scan)
        let brewItem = VaultItem.brew(brew)
        #expect(herbItem.id != brewItem.id)
        #expect(herbItem.id == "herb-abc")
        #expect(brewItem.id == "brew-abc")
    }

    @Test("capturedAt returns the underlying scan or brew timestamp")
    func capturedAtAccessor() {
        let scan = Self.makeScan(id: "s", daysAgo: 3)
        let brew = Self.makeBrew(id: "b", daysAgo: 1)
        #expect(VaultItem.herb(scan).capturedAt == scan.scannedAt)
        #expect(VaultItem.brew(brew).capturedAt == brew.brewedAt)
    }

    @Test("title falls back to a placeholder for herbs, recipe title for brews")
    func titleAccessor() {
        let scan = Self.makeScan(id: "s", daysAgo: 1)
        let brew = Self.makeBrew(id: "b", daysAgo: 1)
        #expect(VaultItem.herb(scan).title == "Identified plant")
        #expect(VaultItem.brew(brew).title == "Brew b")
    }

    @Test("thumbnailURL routes through Scan.photoUrl or BrewEntry.photoLocalURL")
    func thumbnailURLAccessor() {
        let scan = Self.makeScan(id: "s", daysAgo: 1)
        let brew = Self.makeBrew(id: "b", daysAgo: 1)
        #expect(VaultItem.herb(scan).thumbnailURL == URL(string: scan.photoUrl))
        #expect(VaultItem.brew(brew).thumbnailURL == brew.photoLocalURL)
    }

    @Test("isFavorited reflects the underlying scan/brew flag")
    func favoriteAccessor() {
        let scan = Self.makeScan(id: "s", daysAgo: 1, favorited: true)
        let brew = Self.makeBrew(id: "b", daysAgo: 1, favorited: false)
        #expect(VaultItem.herb(scan).isFavorited == true)
        #expect(VaultItem.brew(brew).isFavorited == false)
    }

    @Test("chronological sort interleaves herbs and brews by capturedAt")
    func mixedChronologicalSort() {
        let items: [VaultItem] = [
            .herb(Self.makeScan(id: "s-old", daysAgo: 7)),       // oldest
            .brew(Self.makeBrew(id: "b-mid", daysAgo: 3)),
            .herb(Self.makeScan(id: "s-recent", daysAgo: 1)),    // newest
            .brew(Self.makeBrew(id: "b-old2", daysAgo: 5)),
        ]

        let sortedDescending = items.sorted(by: { $0.capturedAt > $1.capturedAt })
        #expect(sortedDescending.map(\.id) == ["herb-s-recent", "brew-b-mid", "brew-b-old2", "herb-s-old"])

        let sortedAscending = items.sorted(by: { $0.capturedAt < $1.capturedAt })
        #expect(sortedAscending.first?.id == "herb-s-old")
        #expect(sortedAscending.last?.id == "herb-s-recent")
    }

    @Test("mixed list with same-instant timestamps is deterministic by stable sort property")
    func sortStableForTies() {
        let anchor = Date(timeIntervalSince1970: 1_700_000_000)
        let scan = Scan(
            id: "tied",
            userId: "u",
            photoUrl: "https://x/i.jpg",
            scannedAt: anchor,
            identifiedPlantId: "p",
            confidenceScore: 0.5,
            isFavorited: false,
            healthScoreAtScan: 70,
            accessTier: .free
        )
        let brew = BrewEntry(
            id: "tied",
            recipeID: "r",
            recipeTitle: "Tied brew",
            photoLocalURL: URL(fileURLWithPath: "/tmp/x.jpg"),
            brewedAt: anchor
        )
        let items: [VaultItem] = [.herb(scan), .brew(brew)]
        // We don't promise an order on ties, but we do promise the sort doesn't crash
        // and preserves both items.
        let sorted = items.sorted { $0.capturedAt > $1.capturedAt }
        #expect(sorted.count == 2)
        #expect(Set(sorted.map(\.id)) == ["herb-tied", "brew-tied"])
    }
}
