import Foundation

/// On-device store for `BrewEntry` rows. Brews are private journal entries — there's no
/// server-side counterpart in the schema and no need to sync them across devices in V1
/// — so the simplest correct implementation is an actor that owns a single directory:
/// one JSON index (`index.json`) listing every entry, and one JPEG per entry keyed by
/// its `id`.
///
/// The actor pattern (see CLAUDE.md §10.11 and `swift-actor-persistence`) gives us
/// thread-safe access without locks. Initializers take a directory so tests can pass a
/// temp directory and exercise the round-trip without touching the user's real
/// Documents folder.
public actor BrewsLocalRepository {
    public enum Failure: Error, Sendable, Hashable {
        case notFound(id: String)
        case photoWriteFailed
    }

    private let directory: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        directory: URL = BrewsLocalRepository.defaultDirectory,
        fileManager: FileManager = .default
    ) {
        self.directory = directory
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    /// `~/Documents/brews/` on the device. Lazy, so tests that pass an explicit
    /// directory never hit the FileManager call here.
    public nonisolated static var defaultDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return docs.appendingPathComponent("brews", isDirectory: true)
    }

    private var indexURL: URL { directory.appendingPathComponent("index.json") }

    private func ensureDirectory() throws {
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    private func readIndex() throws -> [BrewEntry] {
        try ensureDirectory()
        guard fileManager.fileExists(atPath: indexURL.path) else { return [] }
        let data = try Data(contentsOf: indexURL)
        guard !data.isEmpty else { return [] }
        return try decoder.decode([BrewEntry].self, from: data)
    }

    private func writeIndex(_ entries: [BrewEntry]) throws {
        try ensureDirectory()
        let data = try encoder.encode(entries)
        try data.write(to: indexURL, options: .atomic)
    }

    private func photoURL(for id: String) -> URL {
        directory.appendingPathComponent("\(id).jpg")
    }

    // MARK: - API

    /// All brew entries, newest first. Reads `index.json` from disk on every call —
    /// fine for the hundreds-of-entries scale we expect in the lifetime of one user.
    public func list() async throws -> [BrewEntry] {
        try readIndex().sorted { $0.brewedAt > $1.brewedAt }
    }

    /// Persist `photoData` to `<directory>/<id>.jpg`, then append the entry to
    /// `index.json` with `photoLocalURL` rewritten to point at the file we just wrote.
    /// The returned entry is what callers should hold — its `photoLocalURL` may differ
    /// from the input when the caller passed a placeholder.
    @discardableResult
    public func add(_ entry: BrewEntry, photoData: Data) async throws -> BrewEntry {
        try ensureDirectory()
        let photoTarget = photoURL(for: entry.id)
        do {
            try photoData.write(to: photoTarget, options: .atomic)
        } catch {
            throw Failure.photoWriteFailed
        }

        let stored = BrewEntry(
            id: entry.id,
            recipeID: entry.recipeID,
            recipeTitle: entry.recipeTitle,
            photoLocalURL: photoTarget,
            notes: entry.notes,
            brewedAt: entry.brewedAt,
            isFavorited: entry.isFavorited
        )

        var entries = try readIndex()
        entries.removeAll { $0.id == stored.id }
        entries.append(stored)
        try writeIndex(entries)
        return stored
    }

    /// Flip the favorite flag on an entry. Throws `.notFound` if no entry with that id
    /// exists in the index (callers should guarantee the id by listing first).
    public func toggleFavorite(_ id: String) async throws {
        var entries = try readIndex()
        guard let index = entries.firstIndex(where: { $0.id == id }) else {
            throw Failure.notFound(id: id)
        }
        var entry = entries[index]
        entry.isFavorited.toggle()
        entries[index] = entry
        try writeIndex(entries)
    }

    /// Remove the entry and its photo from disk. Idempotent for the photo (missing file
    /// is OK), but throws `.notFound` if the index doesn't contain the id so the UI
    /// can show a meaningful error rather than silently no-op.
    public func delete(_ id: String) async throws {
        var entries = try readIndex()
        guard let index = entries.firstIndex(where: { $0.id == id }) else {
            throw Failure.notFound(id: id)
        }
        entries.remove(at: index)
        try writeIndex(entries)

        let photo = photoURL(for: id)
        if fileManager.fileExists(atPath: photo.path) {
            try? fileManager.removeItem(at: photo)
        }
    }
}
