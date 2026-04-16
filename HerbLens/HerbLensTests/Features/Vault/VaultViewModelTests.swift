import Foundation
import Testing
@testable import HerbLens

@MainActor
@Suite("VaultViewModel — filter, sort, stats, mutations")
struct VaultViewModelTests {
    private func primedModel(tier: SubscriptionTier = .free) -> VaultViewModel {
        let model = VaultViewModel()
        model.apply(scans: VaultFixtures.scans, plants: VaultFixtures.allPlants, tier: tier)
        return model
    }

    // MARK: - Baseline

    @Test("default displayedRows uses dateNewest and pairs plant with scan")
    func defaultSortAndPairing() {
        let model = primedModel()
        let rows = model.displayedRows
        #expect(rows.count == VaultFixtures.scans.count)
        #expect(rows.first?.scan.id == "s1") // most recent (1 day ago)
        #expect(rows.first?.plant?.commonName == "Chamomile")
    }

    @Test("no-filter state treats scans as presented")
    func hasActiveFiltersFalseInitially() {
        let model = primedModel()
        #expect(model.hasActiveFilters == false)
    }

    // MARK: - Filters

    @Test("category filter returns only scans whose plant matches")
    func categoryFilter() {
        let model = primedModel()
        model.selectedCategory = .flower
        let ids = model.displayedRows.map(\.scan.id)
        #expect(ids.sorted() == ["s1", "s2"])
        #expect(model.hasActiveFilters)
    }

    @Test("favorites-only returns only favorited scans")
    func favoritesOnly() {
        let model = primedModel()
        model.favoritesOnly = true
        let ids = model.displayedRows.map(\.scan.id)
        #expect(ids.sorted() == ["s1", "s4", "s7"])
    }

    @Test("combined category + favorites filter")
    func combinedFilters() {
        let model = primedModel()
        model.selectedCategory = .flower
        model.favoritesOnly = true
        let ids = model.displayedRows.map(\.scan.id)
        #expect(ids == ["s1"])
    }

    @Test("premium goal filter matches plants with relevance >= 50 for that goal")
    func goalFilter() {
        let model = primedModel(tier: .premium)
        model.selectedGoal = "Immunity"
        let ids = model.displayedRows.map(\.scan.id).sorted()
        // basil (65), elderberry (82), reishi (78) — three scans
        #expect(ids == ["s4", "s8", "s9"])
    }

    @Test("goal filter skips plants where the goal's relevance is below 50")
    func goalFilterRelevanceGate() {
        let model = primedModel(tier: .premium)
        let lowRelevance = VaultFixtures.plant(id: "p-low", name: "Sage", category: "Herb", goals: [("Immunity", 30)])
        let scan = VaultFixtures.scan(id: "s-low", plant: lowRelevance, daysAgo: 0, favorited: false, health: 70)
        model.apply(
            scans: VaultFixtures.scans + [scan],
            plants: VaultFixtures.allPlants + [lowRelevance],
            tier: .premium
        )
        model.selectedGoal = "Immunity"
        let ids = model.displayedRows.map(\.scan.id)
        #expect(!ids.contains("s-low"))
    }

    @Test("clearFilters resets everything")
    func clearFilters() {
        let model = primedModel(tier: .premium)
        model.selectedCategory = .flower
        model.favoritesOnly = true
        model.selectedGoal = "Better Sleep"
        model.clearFilters()
        #expect(model.selectedCategory == nil)
        #expect(model.favoritesOnly == false)
        #expect(model.selectedGoal == nil)
        #expect(model.hasActiveFilters == false)
    }

    // MARK: - Sort

    @Test("sort: dateNewest")
    func sortDateNewest() {
        let model = primedModel()
        model.sort = .dateNewest
        let ids = model.displayedRows.map(\.scan.id)
        #expect(ids == ["s1", "s3", "s5", "s2", "s8", "s4", "s6", "s7", "s9"])
    }

    @Test("sort: dateOldest")
    func sortDateOldest() {
        let model = primedModel()
        model.sort = .dateOldest
        let ids = model.displayedRows.map(\.scan.id)
        #expect(ids.first == "s9") // oldest (9 days ago)
        #expect(ids.last == "s1")   // newest (1 day ago)
    }

    @Test("sort: healthScoreDesc")
    func sortHealthScoreDesc() {
        let model = primedModel()
        model.sort = .healthScoreDesc
        let scores = model.displayedRows.map(\.scan.healthScoreAtScan)
        #expect(scores == scores.sorted(by: >))
        #expect(scores.first == 92)
    }

    @Test("sort: nameAsc uses resolved plant commonName")
    func sortNameAsc() {
        let model = primedModel()
        model.sort = .nameAsc
        let names = model.displayedRows.compactMap { $0.plant?.commonName }
        #expect(names == names.sorted(by: { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }))
        #expect(names.first == "Aloe")
    }

    @Test("sort: favoritesFirst groups favorites before non-favorites, newest within each")
    func sortFavoritesFirst() {
        let model = primedModel()
        model.sort = .favoritesFirst
        let rows = model.displayedRows
        let favoritePrefix = rows.prefix { $0.scan.isFavorited }
        #expect(favoritePrefix.count == 3) // s1, s4, s7
        let nonFavorites = rows.dropFirst(favoritePrefix.count)
        #expect(nonFavorites.allSatisfy { !$0.scan.isFavorited })
        #expect(favoritePrefix.map(\.scan.id) == ["s1", "s4", "s7"])
    }

    // MARK: - Stats

    @Test("stats: total scan count")
    func statsTotal() {
        let model = primedModel()
        #expect(model.stats.total == 9)
    }

    @Test("stats: top categories include the two tied Flower/Herb categories")
    func statsTopCategories() {
        let model = primedModel()
        let top = model.stats.topCategories
        #expect(top.count == 3)
        let topTwo = top.prefix(2).map(\.category)
        #expect(topTwo.contains(.flower))
        #expect(topTwo.contains(.herb))
        #expect(top.first?.count == 2)
    }

    @Test("stats: favoriteHerb is the most-scanned plant")
    func statsFavoriteHerb() {
        let model = VaultViewModel()
        let extraScan = VaultFixtures.scan(id: "s-extra", plant: VaultFixtures.chamomile, daysAgo: 0, favorited: false, health: 80)
        model.apply(
            scans: VaultFixtures.scans + [extraScan],
            plants: VaultFixtures.allPlants,
            tier: .premium
        )
        #expect(model.stats.favoriteHerb?.commonName == "Chamomile")
    }

    @Test("stats ignore active filters — always reflect full scan set")
    func statsIgnoreFilters() {
        let model = primedModel(tier: .premium)
        model.selectedCategory = .flower
        model.favoritesOnly = true
        #expect(model.stats.total == 9)
    }

    // MARK: - Mutations

    @Test("toggleFavorite flips local state and calls repo")
    func toggleFavoriteFlipsLocalState() async {
        let model = primedModel()
        let repo = TestScansRepo()
        let before = model.displayedRows.first(where: { $0.scan.id == "s3" })?.scan.isFavorited ?? false
        await model.toggleFavorite(scanID: "s3", using: repo)
        let after = model.displayedRows.first(where: { $0.scan.id == "s3" })?.scan.isFavorited
        #expect(after == !before)
        let calls = await repo.toggleCalls
        #expect(calls == ["s3"])
    }

    @Test("toggleFavorite rolls back on repo error")
    func toggleFavoriteRollsBackOnError() async {
        let model = primedModel()
        let repo = TestScansRepo()
        await repo.setThrowing(true)
        let before = model.displayedRows.first(where: { $0.scan.id == "s3" })?.scan.isFavorited ?? false
        await model.toggleFavorite(scanID: "s3", using: repo)
        let after = model.displayedRows.first(where: { $0.scan.id == "s3" })?.scan.isFavorited
        #expect(after == before)
    }

    @Test("delete removes the scan and decrements stats")
    func deleteRemovesScan() async {
        let model = primedModel(tier: .premium)
        let repo = TestScansRepo()
        #expect(model.stats.total == 9)
        await model.delete(scanID: "s1", using: repo)
        #expect(model.displayedRows.contains(where: { $0.scan.id == "s1" }) == false)
        #expect(model.stats.total == 8)
        let calls = await repo.deleteCalls
        #expect(calls == ["s1"])
    }

    @Test("delete rolls back on repo error")
    func deleteRollsBackOnError() async {
        let model = primedModel()
        let repo = TestScansRepo()
        await repo.setThrowing(true)
        await model.delete(scanID: "s1", using: repo)
        #expect(model.displayedRows.contains(where: { $0.scan.id == "s1" }))
    }

    // MARK: - Paywall hint + availableGoals

    @Test("shouldShowPaywallHint is true for free tier with 3+ scans")
    func paywallHintAppearsForFreeAfterThreeScans() {
        let model = primedModel(tier: .free)
        #expect(model.shouldShowPaywallHint == true)
    }

    @Test("shouldShowPaywallHint is false for premium even with many scans")
    func paywallHintHiddenForPremium() {
        let model = primedModel(tier: .premium)
        #expect(model.shouldShowPaywallHint == false)
    }

    @Test("shouldShowPaywallHint is false when scan count is under 3")
    func paywallHintHiddenForFewScans() {
        let model = VaultViewModel()
        model.apply(
            scans: Array(VaultFixtures.scans.prefix(2)),
            plants: VaultFixtures.allPlants,
            tier: .free
        )
        #expect(model.shouldShowPaywallHint == false)
    }

    @Test("availableGoals is union of goalNames across scanned plants (relevance >= 50)")
    func availableGoals() {
        let model = primedModel(tier: .premium)
        let goals = Set(model.availableGoals)
        #expect(goals.contains("Better Sleep"))
        #expect(goals.contains("Stress Relief"))
        #expect(goals.contains("Digestive"))
        #expect(goals.contains("Immunity"))
        #expect(goals.contains("Pain"))
        #expect(goals.contains("Skin"))
    }
}
