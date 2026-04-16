import Foundation
import Testing
@testable import HerbLens

/// Behavioral coverage for `HomeViewModel`. Uses the canonical `MockServices` plus
/// feature-local stubs for the failure / empty-scans paths.
@MainActor
@Suite("HomeViewModel")
struct HomeViewModelTests {
    private func makeViewModel(
        plants: any PlantsRepository = HomePreviewData.CollectionsRepo(),
        scans: any ScansRepository = MockServices.Scans(),
        subscriptions: any SubscriptionService = MockServices.Subscriptions(),
        auth: any AuthService = MockServices.Auth()
    ) -> HomeViewModel {
        HomeViewModel(plants: plants, scans: scans, subscriptions: subscriptions, auth: auth)
    }

    @Test("load() populates state with 8 collections, featured plants, and tier")
    func loadHappyPath() async {
        let vm = makeViewModel()
        await vm.load()

        guard case .loaded(let data) = vm.state else {
            Issue.record("expected .loaded, got \(vm.state)")
            return
        }
        #expect(data.featured.count >= 3)
        #expect(data.freeCollections.count + data.premiumCollections.count == 8)
        #expect(data.tier == .free)
    }

    @Test("free-tier load splits collections by accessTier")
    func collectionsAreSplitByTier() async {
        let vm = makeViewModel()
        await vm.load()
        guard case .loaded(let data) = vm.state else {
            Issue.record("expected .loaded, got \(vm.state)")
            return
        }
        #expect(data.freeCollections.allSatisfy { $0.accessTier == .free })
        #expect(data.premiumCollections.allSatisfy { $0.accessTier == .premium })
        #expect(data.premiumCollections.count >= 1)
    }

    @Test("premium tier surfaces .premium for downstream gating")
    func premiumTierExposesPremiumSection() async {
        let vm = makeViewModel(subscriptions: HomePreviewData.PremiumSubscriptions())
        await vm.load()
        guard case .loaded(let data) = vm.state else {
            Issue.record("expected .loaded, got \(vm.state)")
            return
        }
        #expect(data.tier == .premium)
        #expect(!data.premiumCollections.isEmpty)
    }

    @Test("refresh() replaces data without flipping back to .loading")
    func refreshReplacesData() async {
        let vm = makeViewModel()
        await vm.load()
        guard case .loaded = vm.state else {
            Issue.record("setup: expected .loaded after initial load")
            return
        }

        await vm.refresh()
        guard case .loaded(let after) = vm.state else {
            Issue.record("expected .loaded after refresh, got \(vm.state)")
            return
        }
        #expect(after.freeCollections.count + after.premiumCollections.count == 8)
    }

    @Test("recents row source is empty when scans repo is empty")
    func recentsHidesWhenScansEmpty() async {
        let vm = makeViewModel(scans: EmptyScansStub())
        await vm.load()
        guard case .loaded(let data) = vm.state else {
            Issue.record("expected .loaded, got \(vm.state)")
            return
        }
        #expect(data.recents.isEmpty)
        #expect(data.recentPlantsByID.isEmpty)
    }

    @Test("plants repo failure surfaces as .failed state")
    func failureSurfacesAsFailedState() async {
        let vm = makeViewModel(plants: ThrowingPlantsRepo())
        await vm.load()
        guard case .failed(let message) = vm.state else {
            Issue.record("expected .failed, got \(vm.state)")
            return
        }
        #expect(!message.isEmpty)
    }

    @Test("idle is the initial state before load() runs")
    func idleBeforeLoad() {
        let vm = makeViewModel()
        #expect(vm.state == .idle)
    }
}

// MARK: - Local test stubs

/// Empty-list scans repo for the recents-hidden path.
private struct EmptyScansStub: ScansRepository {
    func identify(imageData: Data) async throws -> IdentifyResult {
        IdentifyResult(plantID: nil, confidence: 0, suggestedMatches: [])
    }
    func save(_ scan: Scan) async throws -> Scan { scan }
    func list(userID: String, sort: ScanSort, filter: ScanFilter) async throws -> [Scan] { [] }
    func toggleFavorite(scanID: String) async throws {}
    func delete(scanID: String) async throws {}
}

/// PlantsRepository that always throws — exercises the `.failed` path without
/// touching the network or upstream mocks.
private struct ThrowingPlantsRepo: PlantsRepository {
    struct Boom: Error, LocalizedError {
        var errorDescription: String? { "synthetic failure" }
    }
    func featured() async throws -> [Plant] { throw Boom() }
    func plant(id: String) async throws -> Plant { throw Boom() }
    func search(query: String) async throws -> [Plant] { throw Boom() }
    func healthScore(for plantID: String, userID: String) async throws -> HealthScore { throw Boom() }
    func highlightCollections() async throws -> [HighlightCollection] { throw Boom() }
}
