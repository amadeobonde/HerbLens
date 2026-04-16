import Foundation
import Supabase

/// Reads plant catalog data out of Postgres and proxies per-user `health-score` calls
/// through the Supabase edge function (which holds the Gemini API key).
///
/// Plant data is heavily normalized in Postgres — we pull uses, contraindications, and
/// recipes (and their ingredients + steps) via PostgREST embedded selects in a single
/// round trip rather than N+1 queries.
public struct SupabasePlantsRepository: PlantsRepository {
    private let client: SupabaseClient
    private let session: URLSession
    private let baseURL: URL?

    public nonisolated init(
        client: SupabaseClient? = nil,
        session: URLSession = .shared,
        baseURL: URL? = nil
    ) {
        self.client = client ?? SupabaseClientProvider.shared
        self.session = session
        self.baseURL = baseURL
    }

    /// Resolved lazily so tests that never call edge fns don't trigger AppConfig.
    private var resolvedBaseURL: URL { baseURL ?? AppConfig.supabaseURL }

    public func featured() async throws -> [Plant] {
        let rows: [PlantRow] = try await client
            .from("plants")
            .select(PlantRow.fullSelect)
            .eq("featured", value: true)
            .order("common_name", ascending: true)
            .execute()
            .value
        return rows.map { $0.toDomain() }
    }

    public func plant(id: String) async throws -> Plant {
        let row: PlantRow = try await client
            .from("plants")
            .select(PlantRow.fullSelect)
            .eq("id", value: id)
            .single()
            .execute()
            .value
        return row.toDomain()
    }

    public func search(query: String) async throws -> [Plant] {
        // `ilike` on common_name gives us forgiving substring matching. For richer fuzzy
        // matching we'd want a Postgres `tsvector` — deferred until we have real data.
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let rows: [PlantRow] = try await client
            .from("plants")
            .select(PlantRow.fullSelect)
            .ilike("common_name", pattern: "%\(trimmed)%")
            .limit(50)
            .execute()
            .value
        return rows.map { $0.toDomain() }
    }

    public func healthScore(for plantID: String, userID: String) async throws -> HealthScore {
        let url = resolvedBaseURL.appendingPathComponent("/functions/v1/health-score")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = try? await client.auth.session.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try SupabaseJSON.encoder.encode(HealthScoreRequest(plantId: plantID))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw ServiceError.httpStatus(code, body: String(data: data, encoding: .utf8))
        }
        let envelope = try SupabaseJSON.decoder.decode(HealthScoreEnvelope.self, from: data)
        return envelope.healthScore
    }

    public func highlightCollections() async throws -> [HighlightCollection] {
        let rows: [HighlightCollectionRow] = try await client
            .from("highlight_collections")
            .select("""
                id, title, subtitle, cover_image_url, display_order, access_tier,
                highlight_collection_plants ( plant_id )
                """)
            .order("display_order", ascending: true)
            .execute()
            .value
        return rows.map { $0.toDomain() }
    }
}

// MARK: - Row DTOs

/// Nested DTO matching the PostgREST embedded-select output. We map to the domain `Plant`
/// struct here so the rest of the app sees a single flat shape regardless of storage.
struct PlantRow: Decodable {
    let id: String
    let commonName: String
    let alternateNames: [String]?
    let origin: String?
    let regionsFound: [String]?
    let climates: [String]?
    let growingConditions: String?
    let imageUrl: String?
    let thumbnailUrl: String?
    let description: String?
    let tags: [String]?
    let category: String?
    let featured: Bool
    let accessTier: String
    let suggestedPrompts: [String]?
    let lastUpdated: Date
    let plantUses: [PlantUseRow]?
    let plantContraindications: [ContraindicationRow]?
    let recipes: [RecipeRow]?

    /// Single PostgREST select string used everywhere we need a full Plant — keeps the
    /// fetch shape consistent between listing and detail queries.
    static let fullSelect: String = """
        id, common_name, alternate_names, origin, regions_found, climates, growing_conditions,
        image_url, thumbnail_url, description, tags, category, featured, access_tier,
        suggested_prompts, last_updated,
        plant_uses ( category, description, access_tier ),
        plant_contraindications ( condition, details, severity ),
        recipes (
            id, title, type, difficulty, prep_time, steep_or_cure_time, yield, access_tier, image_url,
            recipe_ingredients ( name, amount, notes, sort_order ),
            recipe_steps ( step_number, instruction, tip )
        )
        """

    func toDomain() -> Plant {
        Plant(
            id: id,
            commonName: commonName,
            alternateNames: alternateNames ?? [],
            origin: origin ?? "",
            regionsFound: regionsFound ?? [],
            climates: (climates ?? []).compactMap(Climate.init(rawValue:)),
            growingConditions: growingConditions,
            imageUrl: imageUrl ?? "",
            thumbnailUrl: thumbnailUrl ?? "",
            description: description ?? "",
            tags: tags ?? [],
            category: category ?? "",
            featured: featured,
            accessTier: AccessTier(rawValue: accessTier) ?? .free,
            // Per-user health scores are computed by the edge function, not stored on the
            // catalog row. Feature instances call `healthScore(for:userID:)` separately
            // and merge the result. Until then we surface a neutral placeholder.
            healthScore: HealthScore(overallScore: 0, goalBreakdown: [], warnings: []),
            uses: (plantUses ?? []).map { $0.toDomain() },
            contraindications: (plantContraindications ?? []).map { $0.toDomain() },
            recipes: (recipes ?? []).map { $0.toDomain() },
            suggestedPrompts: suggestedPrompts ?? [],
            lastUpdated: lastUpdated
        )
    }
}

struct PlantUseRow: Decodable {
    let category: String
    let description: String
    let accessTier: String

    func toDomain() -> PlantUse {
        PlantUse(category: category, description: description, accessTier: AccessTier(rawValue: accessTier) ?? .free)
    }
}

struct ContraindicationRow: Decodable {
    let condition: String
    let details: String
    let severity: String

    func toDomain() -> Contraindication {
        Contraindication(condition: condition, details: details, severity: Severity(rawValue: severity) ?? .low)
    }
}

struct RecipeRow: Decodable {
    let id: String
    let title: String
    let type: String
    let difficulty: String
    let prepTime: String?
    let steepOrCureTime: String?
    let yield: String?
    let accessTier: String
    let imageUrl: String?
    let recipeIngredients: [RecipeIngredientRow]?
    let recipeSteps: [RecipeStepRow]?

    func toDomain() -> Recipe {
        Recipe(
            id: id,
            title: title,
            type: RecipeType(rawValue: type) ?? .tea,
            difficulty: Difficulty(rawValue: difficulty) ?? .beginner,
            prepTime: prepTime ?? "",
            steepOrCureTime: steepOrCureTime,
            yield: yield ?? "",
            accessTier: AccessTier(rawValue: accessTier) ?? .premium,
            ingredients: (recipeIngredients ?? [])
                .sorted { $0.sortOrder < $1.sortOrder }
                .map { $0.toDomain() },
            steps: (recipeSteps ?? [])
                .sorted { $0.stepNumber < $1.stepNumber }
                .map { $0.toDomain() },
            imageUrl: imageUrl
        )
    }
}

struct RecipeIngredientRow: Decodable {
    let name: String
    let amount: String
    let notes: String?
    let sortOrder: Int

    func toDomain() -> RecipeIngredient {
        RecipeIngredient(name: name, amount: amount, notes: notes)
    }
}

struct RecipeStepRow: Decodable {
    let stepNumber: Int
    let instruction: String
    let tip: String?

    func toDomain() -> RecipeStep {
        RecipeStep(stepNumber: stepNumber, instruction: instruction, tip: tip)
    }
}

struct HighlightCollectionRow: Decodable {
    let id: String
    let title: String
    let subtitle: String?
    let coverImageUrl: String?
    let displayOrder: Int
    let accessTier: String
    let highlightCollectionPlants: [HighlightCollectionPlantRow]?

    func toDomain() -> HighlightCollection {
        HighlightCollection(
            id: id,
            title: title,
            subtitle: subtitle ?? "",
            coverImageUrl: coverImageUrl ?? "",
            plantIds: (highlightCollectionPlants ?? []).map(\.plantId),
            displayOrder: displayOrder,
            accessTier: AccessTier(rawValue: accessTier) ?? .free
        )
    }
}

struct HighlightCollectionPlantRow: Decodable {
    let plantId: String
}

private struct HealthScoreRequest: Encodable {
    let plantId: String

    enum CodingKeys: String, CodingKey { case plantId = "plant_id" }
}

private struct HealthScoreEnvelope: Decodable {
    let healthScore: HealthScore
}
