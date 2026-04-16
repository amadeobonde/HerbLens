import Foundation
import Supabase

/// `health_profiles` is 1:1 with `user_profiles`, and `health_goals` hangs off the health
/// profile in a separate table. On save we upsert the profile row, then replace the goal
/// rows wholesale — goal counts are small (≤10) so delete-then-insert is simpler and
/// cheaper than per-row diffing.
public struct SupabaseHealthProfileRepository: HealthProfileRepository {
    private let client: SupabaseClient

    public nonisolated init(client: SupabaseClient? = nil) {
        self.client = client ?? SupabaseClientProvider.shared
    }

    public func load(userID: String) async throws -> HealthProfile {
        let rows: [HealthProfileRow] = try await client.from("health_profiles")
            .select("""
                id, user_id, experience_level, allergies, medications, conditions,
                health_goals ( id, name, priority, added_at )
                """)
            .eq("user_id", value: userID)
            .limit(1)
            .execute()
            .value
        return rows.first?.toDomain() ?? .empty
    }

    public func save(_ profile: HealthProfile) async throws {
        guard let userID = try? await client.auth.session.user.id.uuidString else {
            throw ServiceError.unauthenticated
        }
        // 1. Upsert the health profile itself.
        let upsert = HealthProfileUpsert(
            userId: userID,
            experienceLevel: profile.experienceLevel.rawValue,
            allergies: profile.allergies ?? [],
            medications: profile.medications ?? [],
            conditions: profile.conditions ?? []
        )
        let savedRow: SavedHealthProfileRow = try await client.from("health_profiles")
            .upsert(upsert, onConflict: "user_id", returning: .representation)
            .select("id")
            .single()
            .execute()
            .value

        // 2. Replace goals — small N, simpler than diffing.
        try await client.from("health_goals")
            .delete()
            .eq("health_profile_id", value: savedRow.id)
            .execute()

        guard !profile.goals.isEmpty else { return }
        let goalInserts = profile.goals.map {
            HealthGoalInsert(
                healthProfileId: savedRow.id,
                name: $0.name,
                priority: $0.priority
            )
        }
        try await client.from("health_goals").insert(goalInserts).execute()
    }
}

// MARK: - Row / request DTOs

private struct SavedHealthProfileRow: Decodable {
    let id: String
}

private struct HealthProfileUpsert: Encodable {
    let userId: String
    let experienceLevel: String
    let allergies: [String]
    let medications: [String]
    let conditions: [String]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case experienceLevel = "experience_level"
        case allergies, medications, conditions
    }
}

private struct HealthGoalInsert: Encodable {
    let healthProfileId: String
    let name: String
    let priority: Int

    enum CodingKeys: String, CodingKey {
        case healthProfileId = "health_profile_id"
        case name, priority
    }
}
