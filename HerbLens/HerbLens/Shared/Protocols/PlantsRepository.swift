import Foundation

public protocol PlantsRepository: Sendable {
    func featured() async throws -> [Plant]
    func plant(id: String) async throws -> Plant
    func search(query: String) async throws -> [Plant]
    func healthScore(for plantID: String, userID: String) async throws -> HealthScore
    func highlightCollections() async throws -> [HighlightCollection]
}
