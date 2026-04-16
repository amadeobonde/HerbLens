import Foundation

public nonisolated enum SubscriptionTier: String, Codable, Sendable, CaseIterable, Hashable {
    case free
    case premium
}
