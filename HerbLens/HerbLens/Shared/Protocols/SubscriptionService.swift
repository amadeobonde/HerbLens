import Foundation

public protocol SubscriptionService: Sendable {
    func currentTier() async -> SubscriptionTier
    func offerings() async throws -> [Offering]
    func purchase(packageID: String) async throws -> SubscriptionTier
    func restore() async throws -> SubscriptionTier
}
