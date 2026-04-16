import Foundation
import Testing
@testable import HerbLens

@MainActor
@Suite("Onboarding view model — state transitions")
struct OnboardingViewModelStateTests {

    @Test("starts in welcome stage")
    func startsInWelcome() async {
        let vm = makeViewModel()
        #expect(vm.stage == .welcome)
    }

    @Test("startFromWelcome advances to emailEntry")
    func welcomeToEmail() async {
        let vm = makeViewModel()
        vm.startFromWelcome()
        #expect(vm.stage == .emailEntry)
    }

    @Test("submitEmail with valid address → codeEntry + sends magic link")
    func submitEmailHappy() async {
        let auth = SpyAuthService()
        let vm = makeViewModel(auth: auth)
        vm.startFromWelcome()

        await vm.submitEmail("new@user.com")

        #expect(vm.stage == .codeEntry(email: "new@user.com"))
        let calls = await auth.calls
        #expect(calls.sendMagicLink == ["new@user.com"])
    }

    @Test("submitEmail with invalid address → failed stage, no network call")
    func submitEmailInvalid() async {
        let auth = SpyAuthService()
        let vm = makeViewModel(auth: auth)

        await vm.submitEmail("not-an-email")

        if case .failed(_, let retry) = vm.stage {
            #expect(retry == .emailEntry)
        } else {
            Issue.record("expected .failed, got \(vm.stage)")
        }
        let calls = await auth.calls
        #expect(calls.sendMagicLink.isEmpty)
    }

    @Test("submitEmail throws → failed with emailEntry retry target")
    func submitEmailNetworkFails() async {
        let auth = SpyAuthService()
        await auth.setFailMagicLink(true)
        let vm = makeViewModel(auth: auth)

        await vm.submitEmail("user@example.com")

        if case .failed(_, let retry) = vm.stage {
            #expect(retry == .emailEntry)
        } else {
            Issue.record("expected .failed, got \(vm.stage)")
        }
    }

    @Test("verifyCode happy path → wizard(.goals)")
    func verifyCodeHappy() async {
        let auth = SpyAuthService()
        let vm = makeViewModel(auth: auth)
        vm.startFromWelcome()
        await vm.submitEmail("hello@example.com")

        await vm.verifyCode("123456")

        #expect(vm.stage == .wizard(step: .goals))
        let calls = await auth.calls
        #expect(calls.verifyEmailOTP.count == 1)
        #expect(calls.verifyEmailOTP.first?.token == "123456")
    }

    @Test("verifyCode with malformed code → failed with codeEntry retry")
    func verifyCodeMalformed() async {
        let vm = makeViewModel()
        vm.startFromWelcome()
        await vm.submitEmail("hello@example.com")

        await vm.verifyCode("12a")

        if case .failed(_, let retry) = vm.stage {
            #expect(retry == .codeEntry(email: "hello@example.com"))
        } else {
            Issue.record("expected .failed, got \(vm.stage)")
        }
    }

    @Test("verifyCode throws → failed, then retry returns to codeEntry")
    func verifyCodeThrowsThenRetry() async {
        let auth = SpyAuthService()
        await auth.setFailVerify(true)
        let vm = makeViewModel(auth: auth)
        vm.startFromWelcome()
        await vm.submitEmail("retry@example.com")

        await vm.verifyCode("999999")

        if case .failed(_, let retry) = vm.stage {
            #expect(retry == .codeEntry(email: "retry@example.com"))
        } else {
            Issue.record("expected .failed, got \(vm.stage)")
        }

        vm.retry()
        #expect(vm.stage == .codeEntry(email: "retry@example.com"))
    }

    @Test("verifyCode on already-onboarded account → skips wizard, goes to complete")
    func verifyCodeAlreadyOnboarded() async {
        let onboarded = UserProfile(
            id: "u1",
            email: "old@user.com",
            displayName: "Old User",
            subscriptionTier: .premium,
            createdAt: .now,
            updatedAt: .now,
            onboardingCompleted: true,
            healthProfile: HealthProfile(goals: [], experienceLevel: .beginner)
        )
        let auth = SpyAuthService(profile: onboarded)
        let vm = makeViewModel(auth: auth)
        vm.startFromWelcome()
        await vm.submitEmail("old@user.com")

        await vm.verifyCode("111111")

        #expect(vm.stage == .complete(tier: .premium))
    }

    @Test("scenePhaseDidActivate with a session → advance to wizard (magic-link fallback)")
    func scenePhaseFallback() async {
        let auth = SpyAuthService()
        let vm = makeViewModel(auth: auth)
        vm.startFromWelcome()
        await vm.submitEmail("deeplink@example.com")

        // Simulate Supabase SDK processing the deep link and establishing a session.
        await auth.setCurrentUserID("user-123")
        await vm.scenePhaseDidActivate()

        #expect(vm.stage == .wizard(step: .goals))
    }

    @Test("scenePhaseDidActivate without a session → stays in codeEntry")
    func scenePhaseNoSession() async {
        let vm = makeViewModel()
        vm.startFromWelcome()
        await vm.submitEmail("stay@example.com")

        await vm.scenePhaseDidActivate()

        #expect(vm.stage == .codeEntry(email: "stay@example.com"))
    }

    // MARK: - Helpers

    @MainActor
    private func makeViewModel(
        auth: SpyAuthService = SpyAuthService(),
        healthRepo: SpyHealthProfileRepository = SpyHealthProfileRepository(),
        subscriptions: StubSubscriptionService = StubSubscriptionService(tier: .free)
    ) -> OnboardingViewModel {
        OnboardingViewModel(
            auth: auth,
            healthProfileRepo: healthRepo,
            subscriptions: subscriptions
        )
    }
}

@MainActor
@Suite("Onboarding view model — wizard navigation")
struct OnboardingViewModelWizardTests {

    @Test("advance walks all 5 steps")
    func advanceWalksFullFlow() async {
        let vm = await sendToGoals()
        vm.addGoal(named: "Sleep")

        vm.advanceWizard()
        #expect(vm.stage == .wizard(step: .allergies))

        vm.advanceWizard()
        #expect(vm.stage == .wizard(step: .medications))

        vm.advanceWizard()
        #expect(vm.stage == .wizard(step: .conditions))

        vm.advanceWizard()
        #expect(vm.stage == .wizard(step: .experience))
    }

    @Test("goBack from a wizard step returns to previous step")
    func goBackWithinWizard() async {
        let vm = await sendToGoals()
        vm.addGoal(named: "Sleep")
        vm.advanceWizard()
        #expect(vm.stage == .wizard(step: .allergies))

        vm.goBack()
        #expect(vm.stage == .wizard(step: .goals))
    }

    @Test("addGoal / moveGoal produce priorities matching display order")
    func goalsRankingProducesCorrectPriority() async {
        let vm = await sendToGoals()
        vm.addGoal(named: "Sleep")
        vm.addGoal(named: "Energy")
        vm.addGoal(named: "Stress")

        // Move Stress to the top.
        vm.moveGoal(from: IndexSet(integer: 2), to: 0)
        #expect(vm.draftGoals.map(\.name) == ["Stress", "Sleep", "Energy"])
    }

    @Test("addGoal twice with same name is deduplicated")
    func addGoalDedup() async {
        let vm = await sendToGoals()
        vm.addGoal(named: "Sleep")
        vm.addGoal(named: "sleep")
        #expect(vm.draftGoals.count == 1)
    }

    @Test("removeGoal drops the matching entry")
    func removeGoal() async {
        let vm = await sendToGoals()
        vm.addGoal(named: "Sleep")
        vm.addGoal(named: "Energy")
        vm.removeGoal(named: "Sleep")
        #expect(vm.draftGoals.map(\.name) == ["Energy"])
    }

    // MARK: - Helpers

    @MainActor
    private func sendToGoals(
        auth: SpyAuthService = SpyAuthService()
    ) async -> OnboardingViewModel {
        let vm = OnboardingViewModel(
            auth: auth,
            healthProfileRepo: SpyHealthProfileRepository(),
            subscriptions: StubSubscriptionService(tier: .free)
        )
        vm.startFromWelcome()
        await vm.submitEmail("flow@example.com")
        await vm.verifyCode("123456")
        return vm
    }
}

@MainActor
@Suite("Onboarding view model — finalize")
struct OnboardingViewModelFinalizeTests {

    @Test("finalize saves the health profile with priorities and calls completeOnboarding")
    func finalizeSavesProfileAndMarksComplete() async {
        let auth = SpyAuthService()
        let repo = SpyHealthProfileRepository()
        let vm = OnboardingViewModel(
            auth: auth,
            healthProfileRepo: repo,
            subscriptions: StubSubscriptionService(tier: .free)
        )
        vm.startFromWelcome()
        await vm.submitEmail("done@example.com")
        await vm.verifyCode("123456")
        vm.addGoal(named: "Sleep")
        vm.addGoal(named: "Stress")
        vm.draftAllergies = ["Ragweed"]
        vm.draftMedications = []
        vm.draftConditions = ["Pregnant"]
        vm.draftExperience = .intermediate

        await vm.finalize()

        #expect(vm.stage == .complete(tier: .free))

        let saved = await repo.savedProfiles
        #expect(saved.count == 1)
        #expect(saved.first?.goals.map(\.name) == ["Sleep", "Stress"])
        #expect(saved.first?.goals.map(\.priority) == [1, 2])
        #expect(saved.first?.allergies == ["Ragweed"])
        #expect(saved.first?.medications == nil)
        #expect(saved.first?.conditions == ["Pregnant"])
        #expect(saved.first?.experienceLevel == .intermediate)

        let calls = await auth.calls
        #expect(!calls.completeOnboarding.isEmpty)
    }

    @Test("finalize with premium subscription → complete(.premium)")
    func finalizePremium() async {
        let auth = SpyAuthService()
        let vm = OnboardingViewModel(
            auth: auth,
            healthProfileRepo: SpyHealthProfileRepository(),
            subscriptions: StubSubscriptionService(tier: .premium)
        )
        vm.startFromWelcome()
        await vm.submitEmail("pro@example.com")
        await vm.verifyCode("123456")
        vm.addGoal(named: "Sleep")

        await vm.finalize()

        #expect(vm.stage == .complete(tier: .premium))
    }

    @Test("finalize failure → stage transitions to failed(retryTo: .finalizing)")
    func finalizeFails() async {
        let auth = SpyAuthService()
        let repo = SpyHealthProfileRepository()
        await repo.setFailSave(true)
        let vm = OnboardingViewModel(
            auth: auth,
            healthProfileRepo: repo,
            subscriptions: StubSubscriptionService(tier: .free)
        )
        vm.startFromWelcome()
        await vm.submitEmail("fail@example.com")
        await vm.verifyCode("123456")
        vm.addGoal(named: "Sleep")

        await vm.finalize()

        if case .failed(_, let retry) = vm.stage {
            #expect(retry == .finalizing)
        } else {
            Issue.record("expected .failed, got \(vm.stage)")
        }

        let calls = await auth.calls
        #expect(calls.completeOnboarding.isEmpty)
    }
}

@Suite("OnboardingWizardStep — navigation helpers")
struct OnboardingWizardStepTests {

    @Test("step order progresses through all 5 stages")
    func stepOrder() {
        #expect(OnboardingWizardStep.goals.next == .allergies)
        #expect(OnboardingWizardStep.allergies.next == .medications)
        #expect(OnboardingWizardStep.medications.next == .conditions)
        #expect(OnboardingWizardStep.conditions.next == .experience)
        #expect(OnboardingWizardStep.experience.next == nil)
    }

    @Test("previous is nil on the first step")
    func previousBoundary() {
        #expect(OnboardingWizardStep.goals.previous == nil)
        #expect(OnboardingWizardStep.allergies.previous == .goals)
    }

    @Test("total count matches case count")
    func totalMatchesCases() {
        #expect(OnboardingWizardStep.total == 5)
    }
}
