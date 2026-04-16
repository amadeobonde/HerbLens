import Foundation

public nonisolated enum Climate: String, Codable, Sendable, CaseIterable, Hashable {
    case tropical
    case temperate
    case arid
    case subarctic
    case mediterranean
    case subtropical
}
