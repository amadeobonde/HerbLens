import Foundation

public nonisolated struct PlantUse: Codable, Sendable, Hashable {
    public let category: String
    public let description: String
    public let accessTier: AccessTier

    public init(category: String, description: String, accessTier: AccessTier) {
        self.category = category
        self.description = description
        self.accessTier = accessTier
    }
}

public nonisolated struct Contraindication: Codable, Sendable, Hashable {
    public let condition: String
    public let details: String
    public let severity: Severity

    public init(condition: String, details: String, severity: Severity) {
        self.condition = condition
        self.details = details
        self.severity = severity
    }
}

public nonisolated struct Plant: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let commonName: String
    public let alternateNames: [String]
    public let origin: String
    public let regionsFound: [String]
    public let climates: [Climate]
    public let growingConditions: String?
    public let imageUrl: String
    public let thumbnailUrl: String
    public let description: String
    public let tags: [String]
    public let category: String
    public let featured: Bool
    public let accessTier: AccessTier
    public let healthScore: HealthScore
    public let uses: [PlantUse]
    public let contraindications: [Contraindication]
    public let recipes: [Recipe]
    public let suggestedPrompts: [String]
    public let lastUpdated: Date

    public init(
        id: String,
        commonName: String,
        alternateNames: [String],
        origin: String,
        regionsFound: [String],
        climates: [Climate],
        growingConditions: String? = nil,
        imageUrl: String,
        thumbnailUrl: String,
        description: String,
        tags: [String],
        category: String,
        featured: Bool,
        accessTier: AccessTier,
        healthScore: HealthScore,
        uses: [PlantUse],
        contraindications: [Contraindication],
        recipes: [Recipe],
        suggestedPrompts: [String],
        lastUpdated: Date
    ) {
        self.id = id
        self.commonName = commonName
        self.alternateNames = alternateNames
        self.origin = origin
        self.regionsFound = regionsFound
        self.climates = climates
        self.growingConditions = growingConditions
        self.imageUrl = imageUrl
        self.thumbnailUrl = thumbnailUrl
        self.description = description
        self.tags = tags
        self.category = category
        self.featured = featured
        self.accessTier = accessTier
        self.healthScore = healthScore
        self.uses = uses
        self.contraindications = contraindications
        self.recipes = recipes
        self.suggestedPrompts = suggestedPrompts
        self.lastUpdated = lastUpdated
    }
}
