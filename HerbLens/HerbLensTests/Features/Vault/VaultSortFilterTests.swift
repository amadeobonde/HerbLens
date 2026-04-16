import Foundation
import Testing
@testable import HerbLens

@Suite("VaultCategory + VaultStats pure logic")
struct VaultSortFilterTests {
    @Test("VaultCategory.matches is case-insensitive")
    func categoryMatchIsCaseInsensitive() {
        #expect(VaultCategory.flower.matches(plantCategory: "Flower"))
        #expect(VaultCategory.flower.matches(plantCategory: "FLOWER"))
        #expect(VaultCategory.flower.matches(plantCategory: "flower"))
        #expect(!VaultCategory.flower.matches(plantCategory: "Herb"))
    }

    @Test("VaultCategory covers the brief's seven categories")
    func categoryCoverage() {
        let names = VaultCategory.allCases.map(\.displayName).sorted()
        #expect(names == ["Bark", "Berry", "Flower", "Herb", "Leaf", "Mushroom", "Root"])
    }

    @Test("VaultStats.compute returns .empty for an empty scan list")
    func statsEmpty() {
        let stats = VaultStats.compute(scans: [], plantsByID: [:])
        #expect(stats == .empty)
        #expect(stats.total == 0)
        #expect(stats.favoriteHerb == nil)
    }

    @Test("VaultStats.compute skips categories the plant lookup can't resolve")
    func statsSkipsUnresolvedPlants() {
        let scans = VaultFixtures.scans
        let stats = VaultStats.compute(scans: scans, plantsByID: [:])
        #expect(stats.total == scans.count)
        #expect(stats.topCategories.isEmpty) // no plant lookup → no category counts
        #expect(stats.favoriteHerb == nil)
    }

    @Test("VaultStats.compute tiebreaker sorts categories alphabetically by displayName")
    func statsTiebreakerAlphabetical() {
        let a = VaultFixtures.chamomile   // Flower
        let b = VaultFixtures.peppermint  // Herb
        let scans = [
            VaultFixtures.scan(id: "a", plant: a, daysAgo: 1, favorited: false, health: 80),
            VaultFixtures.scan(id: "b", plant: b, daysAgo: 2, favorited: false, health: 80),
        ]
        let plants = [a.id: a, b.id: b]
        let stats = VaultStats.compute(scans: scans, plantsByID: plants)
        // Both counts are 1, so Flower should come before Herb alphabetically.
        #expect(stats.topCategories.map(\.category) == [.flower, .herb])
    }
}
