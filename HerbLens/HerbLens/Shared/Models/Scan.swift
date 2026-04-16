import Foundation

public nonisolated struct Scan: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let userId: String
    public let photoUrl: String
    public let scannedAt: Date
    public let identifiedPlantId: String
    public let confidenceScore: Double
    public let userNotes: String?
    public let isFavorited: Bool
    public let healthScoreAtScan: Int
    public let accessTier: AccessTier

    public init(
        id: String,
        userId: String,
        photoUrl: String,
        scannedAt: Date,
        identifiedPlantId: String,
        confidenceScore: Double,
        userNotes: String? = nil,
        isFavorited: Bool,
        healthScoreAtScan: Int,
        accessTier: AccessTier
    ) {
        self.id = id
        self.userId = userId
        self.photoUrl = photoUrl
        self.scannedAt = scannedAt
        self.identifiedPlantId = identifiedPlantId
        self.confidenceScore = confidenceScore
        self.userNotes = userNotes
        self.isFavorited = isFavorited
        self.healthScoreAtScan = healthScoreAtScan
        self.accessTier = accessTier
    }
}

public nonisolated enum ScanSort: String, Codable, Sendable, CaseIterable, Hashable {
    case newest
    case oldest
    case favoritesFirst
    case healthScoreDescending
}

public nonisolated struct ScanFilter: Codable, Sendable, Hashable {
    public let plantID: String?
    public let isFavorited: Bool?
    public let category: String?
    public let minHealthScore: Int?
    public let maxHealthScore: Int?

    public init(
        plantID: String? = nil,
        isFavorited: Bool? = nil,
        category: String? = nil,
        minHealthScore: Int? = nil,
        maxHealthScore: Int? = nil
    ) {
        self.plantID = plantID
        self.isFavorited = isFavorited
        self.category = category
        self.minHealthScore = minHealthScore
        self.maxHealthScore = maxHealthScore
    }

    public static let none = ScanFilter()
}

public nonisolated struct IdentifyResult: Codable, Sendable, Hashable {
    public let plantID: String?
    public let confidence: Double
    public let suggestedMatches: [Plant]
    public let rawIdentification: String?

    public init(
        plantID: String?,
        confidence: Double,
        suggestedMatches: [Plant],
        rawIdentification: String? = nil
    ) {
        self.plantID = plantID
        self.confidence = confidence
        self.suggestedMatches = suggestedMatches
        self.rawIdentification = rawIdentification
    }
}
