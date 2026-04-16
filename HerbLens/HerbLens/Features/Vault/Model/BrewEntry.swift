import Foundation

/// A user-recorded brew session — one row per time the user actually made a tea or
/// tincture from a `Recipe`. Lives in local storage (see `BrewsLocalRepository`) and
/// composes with `Scan` inside `VaultItem` to power the dual-section vault grid.
///
/// `photoLocalURL` is a file URL into the brews directory managed by the repository
/// (`<directory>/<id>.jpg`). Treat it as opaque — let the repository own the on-disk
/// layout — and just feed it to `Image(contentsOfFile:)` / `AsyncImage(url:)` for
/// display.
public nonisolated struct BrewEntry: Sendable, Identifiable, Hashable, Codable {
    public let id: String
    public let recipeID: String
    public let recipeTitle: String
    public let photoLocalURL: URL
    public let notes: String?
    public let brewedAt: Date
    public var isFavorited: Bool

    public init(
        id: String = UUID().uuidString,
        recipeID: String,
        recipeTitle: String,
        photoLocalURL: URL,
        notes: String? = nil,
        brewedAt: Date = Date(),
        isFavorited: Bool = false
    ) {
        self.id = id
        self.recipeID = recipeID
        self.recipeTitle = recipeTitle
        self.photoLocalURL = photoLocalURL
        self.notes = notes
        self.brewedAt = brewedAt
        self.isFavorited = isFavorited
    }
}
