import Foundation
import Observation
import SwiftUI

/// `@MainActor` is implicit (project default per CLAUDE §10.1). View-state container.
@Observable
@MainActor
final class OnboardingViewModel {
    // Services — held as `any Protocol` so previews/tests can inject mocks or spies.
    let auth: any AuthService
    private let healthProfileRepo: any HealthProfileRepository
    private let subscriptions: any SubscriptionService

    // State
    private(set) var stage: OnboardingStage = .welcome

    // Draft HealthProfile — built up step by step, committed in `finalize()`.
    private(set) var draftGoals: [DraftGoal] = []
    var draftAllergies: [String] = []
    var draftMedications: [String] = []
    var draftConditions: [String] = []
    var draftExperience: ExperienceLevel = .beginner

    // In-flight trackers
    private(set) var isBusy = false

    init(
        auth: any AuthService,
        healthProfileRepo: any HealthProfileRepository,
        subscriptions: any SubscriptionService
    ) {
        self.auth = auth
        self.healthProfileRepo = healthProfileRepo
        self.subscriptions = subscriptions
    }

    // MARK: - Welcome → Email

    func startFromWelcome() {
        stage = .emailEntry
    }

    // MARK: - Email submission

    func submitEmail(_ email: String) async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValidEmail(trimmed) else {
            stage = .failed(message: "Please enter a valid email address.", retryTo: .emailEntry)
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            try await auth.sendMagicLink(email: trimmed)
            stage = .codeEntry(email: trimmed)
        } catch {
            stage = .failed(
                message: "Couldn't send the code. Check your connection and try again.",
                retryTo: .emailEntry
            )
        }
    }

    // MARK: - OTP verification

    func verifyCode(_ code: String) async {
        guard case .codeEntry(let email) = stage else { return }
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 6, trimmed.allSatisfy(\.isNumber) else {
            stage = .failed(message: "Enter the 6-digit code from your email.", retryTo: .codeEntry(email: email))
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            let profile = try await auth.verifyEmailOTP(email: email, token: trimmed)
            routeAfterSignIn(profile: profile)
        } catch {
            stage = .failed(
                message: "That code didn't match. Try again or resend.",
                retryTo: .codeEntry(email: email)
            )
        }
    }

    /// Re-invoked from the UI layer when the scene becomes active, to handle the
    /// magic-link fallback path where the Supabase SDK processes the deep link
    /// and establishes the session behind our back.
    func scenePhaseDidActivate() async {
        guard case .codeEntry = stage else { return }
        guard let userID = await auth.currentUserID, !userID.isEmpty else { return }
        isBusy = true
        defer { isBusy = false }
        // We don't have the profile handy; assume new-user flow. If already
        // onboarded, `finalize` at the end won't hurt — it's idempotent.
        stage = .wizard(step: .goals)
    }

    // MARK: - Wizard transitions

    func advanceWizard() {
        guard case .wizard(let step) = stage else { return }
        if let next = step.next {
            stage = .wizard(step: next)
        } else {
            Task { await finalize() }
        }
    }

    func goBack() {
        switch stage {
        case .codeEntry:
            stage = .emailEntry
        case .wizard(let step):
            if let previous = step.previous {
                stage = .wizard(step: previous)
            }
        case .failed(_, let retryTo):
            stage = retryTo.asStage
        default:
            break
        }
    }

    func retry() {
        if case .failed(_, let retryTo) = stage {
            stage = retryTo.asStage
        }
    }

    // MARK: - Goals draft

    func addGoal(named name: String) {
        guard !draftGoals.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else { return }
        draftGoals.append(DraftGoal(id: UUID().uuidString, name: name))
    }

    func removeGoal(named name: String) {
        draftGoals.removeAll { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    func moveGoal(from source: IndexSet, to destination: Int) {
        draftGoals.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Finalize

    func finalize() async {
        stage = .finalizing
        isBusy = true
        defer { isBusy = false }
        let now = Date()
        let goals = draftGoals.enumerated().map { index, draft in
            HealthGoal(id: draft.id, name: draft.name, priority: index + 1, addedAt: now)
        }
        let profile = HealthProfile(
            goals: goals,
            allergies: draftAllergies.isEmpty ? nil : draftAllergies,
            medications: draftMedications.isEmpty ? nil : draftMedications,
            conditions: draftConditions.isEmpty ? nil : draftConditions,
            experienceLevel: draftExperience
        )
        do {
            try await healthProfileRepo.save(profile)
            if let userID = await auth.currentUserID {
                try await auth.completeOnboarding(userID: userID)
            }
            let tier = await subscriptions.currentTier()
            stage = .complete(tier: tier)
        } catch {
            stage = .failed(
                message: "Couldn't save your profile. Please try again.",
                retryTo: .finalizing
            )
        }
    }

    // MARK: - Helpers

    nonisolated private static func isValidEmail(_ raw: String) -> Bool {
        // Keep this permissive: valid enough for UX, not a spec-perfect RFC parse.
        // The backend is the authority.
        let pattern = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        return raw.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Route after sign-in

    private func routeAfterSignIn(profile: UserProfile) {
        if profile.onboardingCompleted {
            // Edge case: user reinstalled and signed in with an already-onboarded account.
            stage = .complete(tier: profile.subscriptionTier)
        } else {
            stage = .wizard(step: .goals)
        }
    }
}

extension OnboardingViewModel {
    /// Lightweight draft goal before it gets assigned a priority via enumerate.
    struct DraftGoal: Identifiable, Equatable, Hashable, Sendable {
        let id: String
        let name: String
    }
}

private extension OnboardingStage.RetryTarget {
    var asStage: OnboardingStage {
        switch self {
        case .emailEntry: .emailEntry
        case .codeEntry(let email): .codeEntry(email: email)
        case .wizard(let step): .wizard(step: step)
        case .finalizing: .finalizing
        }
    }
}
