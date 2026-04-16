import Foundation

public nonisolated enum WarningType: String, Codable, Sendable, CaseIterable, Hashable {
    case allergy
    case medicationInteraction = "medication_interaction"
    case condition
}

public nonisolated struct GoalBreakdown: Codable, Sendable, Hashable {
    public let goalName: String
    public let relevanceScore: Int
    public let reason: String

    public init(goalName: String, relevanceScore: Int, reason: String) {
        self.goalName = goalName
        self.relevanceScore = relevanceScore
        self.reason = reason
    }
}

public nonisolated struct Warning: Codable, Sendable, Hashable {
    public let type: WarningType
    public let severity: Severity
    public let message: String

    public init(type: WarningType, severity: Severity, message: String) {
        self.type = type
        self.severity = severity
        self.message = message
    }
}

public nonisolated struct HealthScore: Codable, Sendable, Hashable {
    public let overallScore: Int
    public let goalBreakdown: [GoalBreakdown]
    public let warnings: [Warning]

    public init(overallScore: Int, goalBreakdown: [GoalBreakdown], warnings: [Warning]) {
        self.overallScore = overallScore
        self.goalBreakdown = goalBreakdown
        self.warnings = warnings
    }
}
