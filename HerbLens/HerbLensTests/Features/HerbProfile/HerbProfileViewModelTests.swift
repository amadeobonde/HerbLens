import Foundation
import Testing
@testable import HerbLens

/// Test-only stubs. Kept in the test bundle so production code has no test hooks.

nonisolated struct HerbProfileStubPlantsRepository: PlantsRepository {
    let plant: Plant?
    let healthScore: HealthScore
    let error: Error?

    init(plant: Plant?, healthScore: HealthScore, error: Error? = nil) {
        self.plant = plant
        self.healthScore = healthScore
        self.error = error
    }

    func featured() async throws -> [Plant] { [] }

    func plant(id: String) async throws -> Plant {
        if let error { throw error }
        guard let plant else { throw StubError.notFound }
        return plant
    }

    func search(query: String) async throws -> [Plant] { [] }

    func healthScore(for plantID: String, userID: String) async throws -> HealthScore {
        if let error { throw error }
        return healthScore
    }

    func highlightCollections() async throws -> [HighlightCollection] { [] }

    enum StubError: Error { case notFound }
}

nonisolated struct HerbProfileStubSubscriptionService: SubscriptionService {
    let tier: SubscriptionTier

    func currentTier() async -> SubscriptionTier { tier }
    func offerings() async throws -> [Offering] { [] }
    func purchase(packageID: String) async throws -> SubscriptionTier { tier }
    func restore() async throws -> SubscriptionTier { tier }
}

nonisolated struct HerbProfileStubAuthService: AuthService {
    let userID: String?
    var currentUserID: String? { get async { userID } }

    func signUp(email: String, password: String) async throws -> UserProfile {
        throw StubError.notImplemented
    }
    func signIn(email: String, password: String) async throws -> UserProfile {
        throw StubError.notImplemented
    }
    func signOut() async throws {}
    func sendMagicLink(email: String) async throws {}
    func verifyEmailOTP(email: String, token: String) async throws -> UserProfile { throw StubError.notImplemented }
    func signInWithApple(idToken: String, nonce: String) async throws -> UserProfile { throw StubError.notImplemented }
    func signInWithGoogle(idToken: String, accessToken: String) async throws -> UserProfile { throw StubError.notImplemented }
    func completeOnboarding(userID: String) async throws {}

    enum StubError: Error { case notImplemented }
}

@MainActor
@Suite("HerbProfileViewModel load flow")
struct HerbProfileViewModelTests {
    private func makeVM(
        plant: Plant? = SampleData.chamomile,
        healthScore: HealthScore = SampleData.chamomile.healthScore,
        tier: SubscriptionTier = .free,
        error: Error? = nil
    ) -> HerbProfileViewModel {
        HerbProfileViewModel(
            plantID: plant?.id ?? SampleData.chamomile.id,
            plants: HerbProfileStubPlantsRepository(plant: plant, healthScore: healthScore, error: error),
            subscriptions: HerbProfileStubSubscriptionService(tier: tier),
            auth: HerbProfileStubAuthService(userID: SampleData.userID)
        )
    }

    @Test("happy path loads plant + score + tier (free)")
    func happyPathFree() async {
        let vm = makeVM(tier: .free)
        await vm.load()

        let payload = vm.state.payload
        #expect(payload != nil)
        #expect(payload?.plant.id == SampleData.chamomile.id)
        #expect(payload?.tier == .free)
        #expect(payload?.healthScore.overallScore == 92)
    }

    @Test("premium tier flows through to payload")
    func happyPathPremium() async {
        let vm = makeVM(tier: .premium)
        await vm.load()
        #expect(vm.state.payload?.tier == .premium)
    }

    @Test("plant-not-found surfaces as .failed")
    func notFoundFailsLoad() async {
        let vm = makeVM(plant: nil)
        await vm.load()
        #expect(vm.state.payload == nil)
        #expect(vm.state.errorDescription != nil)
    }

    @Test("load is idempotent once loaded")
    func loadIdempotent() async {
        let vm = makeVM(tier: .free)
        await vm.load()
        await vm.load() // second call short-circuits — state stays .loaded
        #expect(vm.state.payload != nil)
    }

    @Test("retry() clears loaded state and re-fetches")
    func retryReloads() async {
        let vm = makeVM(tier: .free)
        await vm.load()
        await vm.retry()
        #expect(vm.state.payload != nil)
    }

    @Test("toggleBreakdown flips expansion flag")
    func toggleBreakdownFlag() {
        let vm = makeVM()
        #expect(vm.isBreakdownExpanded == false)
        vm.toggleBreakdown()
        #expect(vm.isBreakdownExpanded == true)
        vm.toggleBreakdown()
        #expect(vm.isBreakdownExpanded == false)
    }
}
