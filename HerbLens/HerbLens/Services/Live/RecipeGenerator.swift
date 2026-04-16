import Foundation
import Supabase

/// Thin client for the `generate-recipes` Supabase edge function. Calls Gemini
/// via Vertex AI server-side, returning structured `Recipe` JSON for any plant —
/// letting the app extend its recipe library to every herb the user identifies,
/// not just the five we hardcoded.
///
/// Uses the same injectable-URL + `URLSession` pattern as the other live services
/// so tests can inject `URLProtocolStub.session()` + a local base URL. Auth token
/// is pulled from the bundled `SupabaseClient`, matching every other edge-fn call.
public struct RecipeGenerator: Sendable {
    public let session: URLSession
    public let baseURL: URL?

    public nonisolated init(
        session: URLSession = .shared,
        baseURL: URL? = nil
    ) {
        self.session = session
        self.baseURL = baseURL
    }

    /// Ask the edge function to produce 3–5 recipes for a plant. Prefer passing a
    /// `plantID` when the herb is in our catalog so Gemini has full context (uses,
    /// contraindications). Fall back to `plantName` when the user typed in a new
    /// herb or scanned one that didn't match any catalog entry.
    public func generate(plantID: String? = nil, plantName: String? = nil) async throws -> [Recipe] {
        guard plantID != nil || plantName != nil else {
            throw ServiceError.decodingFailed("must provide plantID or plantName")
        }

        let baseURL = baseURL ?? AppConfig.supabaseURL
        let url = baseURL.appendingPathComponent("/functions/v1/generate-recipes")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = try? await SupabaseClientProvider.shared.auth.session.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        var body: [String: Any] = [:]
        if let plantID { body["plant_id"] = plantID }
        if let plantName { body["plant_name"] = plantName }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.httpStatus(-1, body: nil)
        }
        if http.statusCode == 429 {
            // Free-tier daily generation cap hit — callers present the paywall.
            throw ScanError.quotaExceeded(limit: 3)
        }
        guard http.statusCode == 200 else {
            throw ServiceError.httpStatus(http.statusCode, body: String(data: data, encoding: .utf8))
        }

        let envelope = try SupabaseJSON.decoder.decode(RecipeGenerationEnvelope.self, from: data)
        return envelope.recipes.map { $0.toDomain() }
    }
}

// MARK: - Wire DTOs

private struct RecipeGenerationEnvelope: Decodable {
    let recipes: [GeneratedRecipeRow]
}

private struct GeneratedRecipeRow: Decodable {
    let id: String
    let title: String
    let type: String
    let difficulty: String
    let prepTime: String?
    let steepOrCureTime: String?
    let yield: String?
    let accessTier: String
    let ingredients: [GeneratedIngredient]?
    let steps: [GeneratedStep]?

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
            ingredients: (ingredients ?? []).map { $0.toDomain() },
            steps: (steps ?? []).enumerated().map { index, row in
                row.toDomain(defaultStepNumber: index + 1)
            },
            imageUrl: nil
        )
    }
}

private struct GeneratedIngredient: Decodable {
    let name: String
    let amount: String
    let notes: String?

    func toDomain() -> RecipeIngredient {
        RecipeIngredient(name: name, amount: amount, notes: notes)
    }
}

private struct GeneratedStep: Decodable {
    let stepNumber: Int?
    let instruction: String
    let tip: String?

    func toDomain(defaultStepNumber: Int) -> RecipeStep {
        RecipeStep(
            stepNumber: stepNumber ?? defaultStepNumber,
            instruction: instruction,
            tip: tip
        )
    }
}
