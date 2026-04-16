import Foundation

public nonisolated enum ExperienceLevel: String, Codable, Sendable, CaseIterable, Hashable {
    case beginner
    case intermediate
    case advanced
}

public nonisolated struct HealthGoal: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let priority: Int
    public let addedAt: Date

    public init(id: String, name: String, priority: Int, addedAt: Date) {
        self.id = id
        self.name = name
        self.priority = priority
        self.addedAt = addedAt
    }
}

public nonisolated struct HealthProfile: Codable, Sendable, Hashable {
    public let goals: [HealthGoal]
    public let allergies: [String]?
    public let medications: [String]?
    public let conditions: [String]?
    public let experienceLevel: ExperienceLevel

    public init(
        goals: [HealthGoal],
        allergies: [String]? = nil,
        medications: [String]? = nil,
        conditions: [String]? = nil,
        experienceLevel: ExperienceLevel
    ) {
        self.goals = goals
        self.allergies = allergies
        self.medications = medications
        self.conditions = conditions
        self.experienceLevel = experienceLevel
    }
}

public nonisolated struct UserProfile: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let email: String
    public let displayName: String
    public let avatarUrl: String?
    public let subscriptionTier: SubscriptionTier
    public let createdAt: Date
    public let updatedAt: Date
    public let onboardingCompleted: Bool
    public let healthProfile: HealthProfile

    public init(
        id: String,
        email: String,
        displayName: String,
        avatarUrl: String? = nil,
        subscriptionTier: SubscriptionTier,
        createdAt: Date,
        updatedAt: Date,
        onboardingCompleted: Bool,
        healthProfile: HealthProfile
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.subscriptionTier = subscriptionTier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.onboardingCompleted = onboardingCompleted
        self.healthProfile = healthProfile
    }
}
