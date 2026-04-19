import Foundation
import Supabase

/// Scans vault + AI identification. All users get unlimited scans; premium gates content
/// depth (health score breakdowns, recipes, AI chat), not scan count.
public struct SupabaseScansRepository: ScansRepository {
    private let client: SupabaseClient
    private let session: URLSession
    private let plants: any PlantsRepository
    private let baseURL: URL?

    public nonisolated init(
        client: SupabaseClient? = nil,
        session: URLSession = .shared,
        plants: (any PlantsRepository)? = nil,
        baseURL: URL? = nil
    ) {
        self.client = client ?? SupabaseClientProvider.shared
        self.session = session
        self.plants = plants ?? SupabasePlantsRepository()
        self.baseURL = baseURL
    }

    private var resolvedBaseURL: URL { baseURL ?? AppConfig.supabaseURL }

    // MARK: - Identify (edge fn)

    public func identify(imageData: Data) async throws -> IdentifyResult {
        let url = resolvedBaseURL.appendingPathComponent("/functions/v1/identify-plant")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = try? await client.auth.session.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body = IdentifyRequest(imageBase64: imageData.base64EncodedString(), mimeType: "image/jpeg")
        request.httpBody = try SupabaseJSON.encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw ServiceError.httpStatus(code, body: String(data: data, encoding: .utf8))
        }
        let envelope = try SupabaseJSON.decoder.decode(IdentifyEnvelope.self, from: data)
        return try await mapToDomain(envelope.identification)
    }

    // MARK: - CRUD

    public func save(_ scan: Scan) async throws -> Scan {
        let insert = ScanInsert(from: scan)
        let row: ScanRow = try await client.from("scans")
            .insert(insert, returning: .representation)
            .select()
            .single()
            .execute()
            .value
        return row.toDomain()
    }

    public func list(
        userID: String,
        sort: ScanSort,
        filter: ScanFilter
    ) async throws -> [Scan] {
        var query = client.from("scans")
            .select()
            .eq("user_id", value: userID)

        if let plantID = filter.plantID {
            query = query.eq("identified_plant_id", value: plantID)
        }
        if let favorited = filter.isFavorited {
            query = query.eq("is_favorited", value: favorited)
        }
        if let minScore = filter.minHealthScore {
            query = query.gte("health_score_at_scan", value: minScore)
        }
        if let maxScore = filter.maxHealthScore {
            query = query.lte("health_score_at_scan", value: maxScore)
        }

        let ordered: PostgrestTransformBuilder
        switch sort {
        case .newest:
            ordered = query.order("scanned_at", ascending: false)
        case .oldest:
            ordered = query.order("scanned_at", ascending: true)
        case .favoritesFirst:
            ordered = query
                .order("is_favorited", ascending: false)
                .order("scanned_at", ascending: false)
        case .healthScoreDescending:
            ordered = query.order("health_score_at_scan", ascending: false)
        }

        let rows: [ScanRow] = try await ordered.execute().value
        return rows.map { $0.toDomain() }
    }

    public func toggleFavorite(scanID: String) async throws {
        // A single RPC would be nicer, but we don't need one yet — the two-step version is
        // cheap and avoids a custom Postgres function per feature.
        let current: ScanRow = try await client.from("scans")
            .select()
            .eq("id", value: scanID)
            .single()
            .execute()
            .value
        try await client.from("scans")
            .update(["is_favorited": !current.isFavorited])
            .eq("id", value: scanID)
            .execute()
    }

    public func delete(scanID: String) async throws {
        try await client.from("scans")
            .delete()
            .eq("id", value: scanID)
            .execute()
    }

    // MARK: - Identify envelope → domain

    private func mapToDomain(_ identification: IdentifyEdgeResponse) async throws -> IdentifyResult {
        // Edge fn returns plant_name + scientific_name strings; we resolve those to
        // catalog Plant IDs via a search lookup so the caller gets usable matches.
        let suggested: [Plant] = try await resolveSuggestions(identification: identification)
        let topID = suggested.first?.id
        return IdentifyResult(
            plantID: topID,
            confidence: identification.confidence,
            suggestedMatches: suggested,
            rawIdentification: identification.description
        )
    }

    private func resolveSuggestions(identification: IdentifyEdgeResponse) async throws -> [Plant] {
        var seenIDs = Set<String>()
        var resolved: [Plant] = []
        let candidateNames = ([identification.plantName] + identification.candidates.map(\.plantName))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        for name in candidateNames {
            let matches = try await plants.search(query: name)
            if let top = matches.first, !seenIDs.contains(top.id) {
                resolved.append(top)
                seenIDs.insert(top.id)
            }
        }
        return resolved
    }
}

// MARK: - Row / request DTOs

struct ScanRow: Decodable {
    let id: String
    let userId: String
    let photoUrl: String
    let scannedAt: Date
    let identifiedPlantId: String?
    let confidenceScore: Double?
    let userNotes: String?
    let isFavorited: Bool
    let healthScoreAtScan: Int?

    func toDomain() -> Scan {
        Scan(
            id: id,
            userId: userId,
            photoUrl: photoUrl,
            scannedAt: scannedAt,
            identifiedPlantId: identifiedPlantId ?? "",
            confidenceScore: confidenceScore ?? 0,
            userNotes: userNotes,
            isFavorited: isFavorited,
            healthScoreAtScan: healthScoreAtScan ?? 0,
            // `scans` table doesn't track access_tier; the vault item inherits it from the
            // identified plant at display time. Default to free here so clients don't block
            // users from viewing their own scans.
            accessTier: .free
        )
    }
}

private struct ScanInsert: Encodable {
    let id: String?
    let userId: String
    let photoUrl: String
    let scannedAt: Date
    let identifiedPlantId: String?
    let confidenceScore: Double
    let userNotes: String?
    let isFavorited: Bool
    let healthScoreAtScan: Int

    init(from scan: Scan) {
        self.id = scan.id.isEmpty ? nil : scan.id
        self.userId = scan.userId
        self.photoUrl = scan.photoUrl
        self.scannedAt = scan.scannedAt
        self.identifiedPlantId = scan.identifiedPlantId.isEmpty ? nil : scan.identifiedPlantId
        self.confidenceScore = scan.confidenceScore
        self.userNotes = scan.userNotes
        self.isFavorited = scan.isFavorited
        self.healthScoreAtScan = scan.healthScoreAtScan
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case photoUrl = "photo_url"
        case scannedAt = "scanned_at"
        case identifiedPlantId = "identified_plant_id"
        case confidenceScore = "confidence_score"
        case userNotes = "user_notes"
        case isFavorited = "is_favorited"
        case healthScoreAtScan = "health_score_at_scan"
    }
}

private struct IdentifyRequest: Encodable {
    let imageBase64: String
    let mimeType: String

    enum CodingKeys: String, CodingKey {
        case imageBase64 = "image_base64"
        case mimeType = "mime_type"
    }
}

private struct IdentifyEnvelope: Decodable {
    let identification: IdentifyEdgeResponse
}

private struct IdentifyEdgeResponse: Decodable {
    let plantName: String
    let confidence: Double
    let scientificName: String?
    let description: String?
    let properties: [String]?
    let candidates: [IdentifyCandidate]

    enum CodingKeys: String, CodingKey {
        case plantName = "plant_name"
        case confidence
        case scientificName = "scientific_name"
        case description
        case properties
        case candidates
    }
}

private struct IdentifyCandidate: Decodable {
    let plantName: String
    let confidence: Double
    let scientificName: String?

    enum CodingKeys: String, CodingKey {
        case plantName = "plant_name"
        case confidence
        case scientificName = "scientific_name"
    }
}
