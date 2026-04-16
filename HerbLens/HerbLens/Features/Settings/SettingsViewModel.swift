import Foundation
import Observation

/// Drives the Settings screen. Orchestrates user profile, health profile, and
/// subscription tier data; exposes intents for editing the health profile, refreshing
/// the subscription tier after a paywall dismissal, and signing out.
///
/// The VM owns an editable copy of the `HealthProfile` so the inline editor can mutate
/// without writing back to the repo on every keystroke — `saveHealthProfile()` commits.
@MainActor
@Observable
final class SettingsViewModel {
    // MARK: - Loaded data

    private(set) var profile: UserProfile?
    private(set) var healthProfile: HealthProfile?
    private(set) var tier: SubscriptionTier = .free

    // MARK: - UI state

    private(set) var isLoading: Bool = false
    private(set) var isSavingHealth: Bool = false
    private(set) var errorMessage: String?
    private(set) var hasSignedOut: Bool = false
    var healthDraft: HealthProfileDraft = .empty

    // MARK: - Derived

    /// Human-readable current-tier label for the subscription row.
    var subscriptionSummary: String {
        switch tier {
        case .free:
            return "Free — 3 scans a day"
        case .premium:
            return "HerbLens Pro — the full apothecary"
        }
    }

    var isPremium: Bool { tier == .premium }

    /// True when the draft diverges from what's persisted. Drives the Save button.
    var isHealthDirty: Bool {
        guard let healthProfile else { return false }
        return healthDraft != HealthProfileDraft(profile: healthProfile)
    }

    // MARK: - Intents

    func load(
        auth: any AuthService,
        healthRepo: any HealthProfileRepository,
        subscriptions: any SubscriptionService,
        cachedProfile: UserProfile? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let loadedTier = subscriptions.currentTier()

            if let cachedProfile {
                profile = cachedProfile
                healthProfile = cachedProfile.healthProfile
                healthDraft = HealthProfileDraft(profile: cachedProfile.healthProfile)
            } else if let userID = await auth.currentUserID {
                let loadedHealth = try await healthRepo.load(userID: userID)
                healthProfile = loadedHealth
                healthDraft = HealthProfileDraft(profile: loadedHealth)
            } else {
                errorMessage = "You're signed out. Please sign in to see your settings."
            }

            tier = await loadedTier
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    /// Called after the paywall sheet dismisses — re-reads the tier so the subscription
    /// row flips to "Pro" immediately without a full reload.
    func refreshTier(subscriptions: any SubscriptionService) async {
        tier = await subscriptions.currentTier()
    }

    func saveHealthProfile(using repo: any HealthProfileRepository) async {
        guard !isSavingHealth else { return }
        isSavingHealth = true
        errorMessage = nil
        defer { isSavingHealth = false }

        let updated = healthDraft.buildProfile(preservingGoalIDsFrom: healthProfile)
        do {
            try await repo.save(updated)
            healthProfile = updated
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func signOut(auth: any AuthService) async {
        do {
            try await auth.signOut()
            hasSignedOut = true
            profile = nil
            healthProfile = nil
            healthDraft = .empty
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    // MARK: - Testing affordance

    func apply(profile: UserProfile, tier: SubscriptionTier) {
        self.profile = profile
        self.healthProfile = profile.healthProfile
        self.healthDraft = HealthProfileDraft(profile: profile.healthProfile)
        self.tier = tier
    }

    // MARK: - Private

    private func friendlyMessage(for error: Error) -> String {
        if let serviceError = error as? ServiceError {
            switch serviceError {
            case .unauthenticated:
                return "You're signed out. Please sign back in."
            case .httpStatus(let code, _):
                return "Couldn't reach your account (status \(code))."
            case .decodingFailed:
                return "Your profile data looked off — try again."
            case .malformedURL:
                return "Couldn't reach your account. Try again."
            }
        }
        return "Something went wrong."
    }
}

/// Mutable draft of `HealthProfile`. Lets the editor bind to value-typed state and only
/// reconstruct a fresh `HealthProfile` when saving. Goals become `HealthGoalDraft` so
/// drag-to-reorder can shuffle the collection without touching the immutable model.
nonisolated struct HealthProfileDraft: Equatable, Sendable {
    var goals: [HealthGoalDraft]
    var allergies: [String]
    var medications: [String]
    var conditions: [String]
    var experienceLevel: ExperienceLevel

    static let empty = HealthProfileDraft(
        goals: [],
        allergies: [],
        medications: [],
        conditions: [],
        experienceLevel: .beginner
    )

    init(
        goals: [HealthGoalDraft],
        allergies: [String],
        medications: [String],
        conditions: [String],
        experienceLevel: ExperienceLevel
    ) {
        self.goals = goals
        self.allergies = allergies
        self.medications = medications
        self.conditions = conditions
        self.experienceLevel = experienceLevel
    }

    init(profile: HealthProfile) {
        self.goals = profile.goals.map { HealthGoalDraft(goal: $0) }
        self.allergies = profile.allergies ?? []
        self.medications = profile.medications ?? []
        self.conditions = profile.conditions ?? []
        self.experienceLevel = profile.experienceLevel
    }

    /// Build a `HealthProfile` suitable for persistence. Preserves goal IDs / addedAt
    /// from the originally-loaded profile when names line up so the server doesn't see
    /// churn on unrelated goals.
    func buildProfile(preservingGoalIDsFrom previous: HealthProfile?) -> HealthProfile {
        let existingByName: [String: HealthGoal] = Dictionary(
            uniqueKeysWithValues: (previous?.goals ?? []).map { ($0.name, $0) }
        )
        let rebuiltGoals = goals.enumerated().map { index, draft -> HealthGoal in
            let priority = index + 1
            if let match = existingByName[draft.name] {
                return HealthGoal(id: match.id, name: draft.name, priority: priority, addedAt: match.addedAt)
            }
            return HealthGoal(
                id: UUID().uuidString,
                name: draft.name,
                priority: priority,
                addedAt: Date()
            )
        }
        return HealthProfile(
            goals: rebuiltGoals,
            allergies: allergies.isEmpty ? nil : allergies,
            medications: medications.isEmpty ? nil : medications,
            conditions: conditions.isEmpty ? nil : conditions,
            experienceLevel: experienceLevel
        )
    }
}

nonisolated struct HealthGoalDraft: Identifiable, Equatable, Sendable {
    let id: String
    var name: String

    init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }

    init(goal: HealthGoal) {
        self.id = goal.id
        self.name = goal.name
    }
}
