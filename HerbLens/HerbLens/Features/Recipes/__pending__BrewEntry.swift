import Foundation

/// **Pending — Vault (Agent B3) owns the canonical type.**
///
/// Local stub for the brew log entry that the Recipes finish flow writes when
/// a user wraps a brew (photo + optional note + recipe metadata). When the
/// Vault feature lands, this type moves to `Shared/Models/BrewEntry.swift`
/// and gains a `BrewEntriesRepository` protocol; until then we persist via
/// `MadeRecipesStore.appendBrew(_:)` so the finish flow has somewhere to land.
///
/// Logged in `.claude/parallel-instances.md` under "Pending requests to
/// Shared/Services" so Vault picks it up.
public nonisolated struct BrewEntry: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let recipeID: String
    public let recipeTitle: String
    public let createdAt: Date
    public let photoData: Data?
    public let note: String?

    public init(
        id: String = UUID().uuidString,
        recipeID: String,
        recipeTitle: String,
        createdAt: Date = .init(),
        photoData: Data? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.recipeID = recipeID
        self.recipeTitle = recipeTitle
        self.createdAt = createdAt
        self.photoData = photoData
        self.note = note
    }
}
