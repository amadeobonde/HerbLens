import Foundation

public nonisolated struct Offering: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let packageID: String
    public let displayName: String
    public let priceString: String
    public let tier: SubscriptionTier
    public let periodDescription: String?
    public let trialDays: Int?

    public init(
        id: String,
        packageID: String,
        displayName: String,
        priceString: String,
        tier: SubscriptionTier,
        periodDescription: String? = nil,
        trialDays: Int? = nil
    ) {
        self.id = id
        self.packageID = packageID
        self.displayName = displayName
        self.priceString = priceString
        self.tier = tier
        self.periodDescription = periodDescription
        self.trialDays = trialDays
    }
}
