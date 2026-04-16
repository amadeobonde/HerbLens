import Foundation

public protocol HealthProfileRepository: Sendable {
    func load(userID: String) async throws -> HealthProfile
    func save(_ profile: HealthProfile) async throws
}
