import Foundation

public nonisolated struct HighlightCollection: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let coverImageUrl: String
    public let plantIds: [String]
    public let displayOrder: Int
    public let accessTier: AccessTier

    public init(
        id: String,
        title: String,
        subtitle: String,
        coverImageUrl: String,
        plantIds: [String],
        displayOrder: Int,
        accessTier: AccessTier
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coverImageUrl = coverImageUrl
        self.plantIds = plantIds
        self.displayOrder = displayOrder
        self.accessTier = accessTier
    }
}
