import Foundation

public nonisolated enum Severity: String, Codable, Sendable, CaseIterable, Hashable {
    case low
    case moderate
    case high
}
