import Foundation

public nonisolated enum AccessTier: String, Codable, Sendable, CaseIterable, Hashable {
    case free
    case premium
}
