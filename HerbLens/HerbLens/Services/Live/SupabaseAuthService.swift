import Foundation
import Supabase

/// Supabase GoTrue-backed auth. On first sign-up we also create the paired `user_profiles`
/// row so every downstream query can JOIN against a guaranteed-present record.
public struct SupabaseAuthService: AuthService {
    private let client: SupabaseClient

    public nonisolated init(client: SupabaseClient? = nil) {
        self.client = client ?? SupabaseClientProvider.shared
    }

    public var currentUserID: String? {
        get async {
            try? await client.auth.session.user.id.uuidString
        }
    }

    public func signUp(email: String, password: String) async throws -> UserProfile {
        let response = try await client.auth.signUp(email: email, password: password)
        // signUp returns a session only if email confirmations are disabled; either way
        // we get back the new user.
        let userID = response.user.id.uuidString
        if let existing = try await fetchProfile(userID: userID) {
            return existing
        }
        return try await createProfile(userID: userID, email: email)
    }

    public func signIn(email: String, password: String) async throws -> UserProfile {
        let session = try await client.auth.signIn(email: email, password: password)
        let userID = session.user.id.uuidString
        if let existing = try await fetchProfile(userID: userID) {
            return existing
        }
        return try await createProfile(userID: userID, email: email)
    }

    public func signOut() async throws {
        try await client.auth.signOut()
    }

    public func sendMagicLink(email: String) async throws {
        try await client.auth.signInWithOTP(email: email)
    }

    // MARK: - Profile helpers

    private func fetchProfile(userID: String) async throws -> UserProfile? {
        let row: UserProfileRow? = try await client
            .from("user_profiles")
            .select("""
                id, email, display_name, avatar_url, subscription_tier,
                onboarding_completed, created_at, updated_at,
                health_profiles ( experience_level, allergies, medications, conditions,
                                  health_goals ( id, name, priority, added_at ) )
                """)
            .eq("id", value: userID)
            .limit(1)
            .execute()
            .value
        return row?.toDomain()
    }

    private func createProfile(userID: String, email: String) async throws -> UserProfile {
        let insert = NewUserProfileInsert(id: userID, email: email)
        try await client.from("user_profiles").insert(insert).execute()
        try await client.from("health_profiles")
            .insert(NewHealthProfileInsert(userId: userID))
            .execute()
        // Re-fetch so created_at / updated_at are accurate server values.
        guard let profile = try await fetchProfile(userID: userID) else {
            throw ServiceError.decodingFailed("profile inserted but not readable back")
        }
        return profile
    }
}

// MARK: - Row DTOs

/// PostgREST returns joined tables as nested arrays. We model that shape here, then
/// collapse it into the flat `UserProfile` domain struct Shared/ publishes.
private struct UserProfileRow: Decodable {
    let id: String
    let email: String
    let displayName: String?
    let avatarUrl: String?
    let subscriptionTier: String
    let onboardingCompleted: Bool
    let createdAt: Date
    let updatedAt: Date
    let healthProfiles: [HealthProfileRow]?

    func toDomain() -> UserProfile {
        UserProfile(
            id: id,
            email: email,
            displayName: displayName ?? email.split(separator: "@").first.map(String.init) ?? "HerbLens User",
            avatarUrl: avatarUrl,
            subscriptionTier: SubscriptionTier(rawValue: subscriptionTier) ?? .free,
            createdAt: createdAt,
            updatedAt: updatedAt,
            onboardingCompleted: onboardingCompleted,
            healthProfile: healthProfiles?.first?.toDomain() ?? .empty
        )
    }
}

struct HealthProfileRow: Decodable {
    let experienceLevel: String
    let allergies: [String]?
    let medications: [String]?
    let conditions: [String]?
    let healthGoals: [HealthGoalRow]?

    func toDomain() -> HealthProfile {
        HealthProfile(
            goals: (healthGoals ?? []).map { $0.toDomain() }.sorted { $0.priority < $1.priority },
            allergies: allergies,
            medications: medications,
            conditions: conditions,
            experienceLevel: ExperienceLevel(rawValue: experienceLevel) ?? .beginner
        )
    }
}

struct HealthGoalRow: Decodable {
    let id: String
    let name: String
    let priority: Int
    let addedAt: Date

    func toDomain() -> HealthGoal {
        HealthGoal(id: id, name: name, priority: priority, addedAt: addedAt)
    }
}

extension HealthProfile {
    /// Default profile created at sign-up before the user completes onboarding.
    static let empty = HealthProfile(
        goals: [],
        allergies: nil,
        medications: nil,
        conditions: nil,
        experienceLevel: .beginner
    )
}

private struct NewUserProfileInsert: Encodable {
    let id: String
    let email: String
    let onboardingCompleted = false
    let subscriptionTier = "free"

    enum CodingKeys: String, CodingKey {
        case id, email
        case onboardingCompleted = "onboarding_completed"
        case subscriptionTier = "subscription_tier"
    }
}

private struct NewHealthProfileInsert: Encodable {
    let userId: String
    let experienceLevel = "beginner"

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case experienceLevel = "experience_level"
    }
}
