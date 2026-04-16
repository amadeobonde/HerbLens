import Foundation
import Testing
@testable import HerbLens

/// Round-trip the `BrewsLocalRepository` against a temp directory: add → list → toggle
/// → delete. Each test gets its own UUID-named directory so the suite is parallel-safe
/// (Swift Testing runs `@Test` cases concurrently by default).
@Suite("BrewsLocalRepository — disk round-trip")
struct BrewsLocalRepositoryTests {
    private static func makeTempDirectory() -> URL {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("brews-tests-\(UUID().uuidString)", isDirectory: true)
        return tmp
    }

    private static func makeEntry(
        id: String = UUID().uuidString,
        title: String = "Chamomile Sleep Tea",
        favorited: Bool = false
    ) -> BrewEntry {
        BrewEntry(
            id: id,
            recipeID: "recipe-\(id)",
            recipeTitle: title,
            // Placeholder URL — the repo overwrites this with the actual on-disk path
            // when add() runs, so the input value is irrelevant beyond satisfying the
            // initializer.
            photoLocalURL: URL(fileURLWithPath: "/dev/null"),
            notes: "Notes for \(title)",
            brewedAt: Date(timeIntervalSince1970: 1_700_000_000),
            isFavorited: favorited
        )
    }

    private static let samplePhotoData: Data = {
        // 10 bytes is enough to verify a write happened — we don't decode JPEG bytes.
        Data(repeating: 0xFF, count: 10)
    }()

    // MARK: -

    @Test("init does not eagerly create the directory")
    func initIsLazy() async {
        let dir = Self.makeTempDirectory()
        _ = BrewsLocalRepository(directory: dir)
        #expect(FileManager.default.fileExists(atPath: dir.path) == false)
    }

    @Test("add writes the photo file and persists the entry")
    func addRoundTrip() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = BrewsLocalRepository(directory: dir)

        let stored = try await repo.add(Self.makeEntry(id: "brew-1"), photoData: Self.samplePhotoData)

        #expect(stored.id == "brew-1")
        #expect(stored.photoLocalURL.lastPathComponent == "brew-1.jpg")

        // Photo file written + readable.
        #expect(FileManager.default.fileExists(atPath: stored.photoLocalURL.path))
        let written = try Data(contentsOf: stored.photoLocalURL)
        #expect(written == Self.samplePhotoData)

        // Index file populated and decodable.
        let listed = try await repo.list()
        #expect(listed.count == 1)
        #expect(listed.first?.id == "brew-1")
        #expect(listed.first?.photoLocalURL == stored.photoLocalURL)
    }

    @Test("list returns entries sorted newest brewedAt first")
    func listSortsNewestFirst() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = BrewsLocalRepository(directory: dir)

        let older = BrewEntry(
            id: "brew-old",
            recipeID: "r1",
            recipeTitle: "Old brew",
            photoLocalURL: URL(fileURLWithPath: "/dev/null"),
            brewedAt: Date(timeIntervalSince1970: 1_000_000)
        )
        let newer = BrewEntry(
            id: "brew-new",
            recipeID: "r2",
            recipeTitle: "Newer brew",
            photoLocalURL: URL(fileURLWithPath: "/dev/null"),
            brewedAt: Date(timeIntervalSince1970: 2_000_000)
        )

        _ = try await repo.add(older, photoData: Self.samplePhotoData)
        _ = try await repo.add(newer, photoData: Self.samplePhotoData)

        let listed = try await repo.list()
        #expect(listed.map(\.id) == ["brew-new", "brew-old"])
    }

    @Test("toggleFavorite flips isFavorited and persists")
    func toggleFavoriteFlipsPersistedState() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = BrewsLocalRepository(directory: dir)

        _ = try await repo.add(Self.makeEntry(id: "brew-fav"), photoData: Self.samplePhotoData)

        try await repo.toggleFavorite("brew-fav")
        #expect(try await repo.list().first?.isFavorited == true)

        try await repo.toggleFavorite("brew-fav")
        #expect(try await repo.list().first?.isFavorited == false)
    }

    @Test("toggleFavorite throws notFound for an unknown id")
    func toggleFavoriteUnknownIDThrows() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = BrewsLocalRepository(directory: dir)

        await #expect(throws: BrewsLocalRepository.Failure.notFound(id: "missing")) {
            try await repo.toggleFavorite("missing")
        }
    }

    @Test("delete removes the entry from the index and the photo from disk")
    func deleteRemovesEntryAndPhoto() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = BrewsLocalRepository(directory: dir)

        let stored = try await repo.add(Self.makeEntry(id: "brew-del"), photoData: Self.samplePhotoData)
        #expect(FileManager.default.fileExists(atPath: stored.photoLocalURL.path))

        try await repo.delete("brew-del")

        #expect(try await repo.list().isEmpty)
        #expect(FileManager.default.fileExists(atPath: stored.photoLocalURL.path) == false)
    }

    @Test("delete throws notFound for an unknown id")
    func deleteUnknownIDThrows() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = BrewsLocalRepository(directory: dir)

        await #expect(throws: BrewsLocalRepository.Failure.notFound(id: "ghost")) {
            try await repo.delete("ghost")
        }
    }

    @Test("entries survive across repository instances on the same directory")
    func entriesPersistAcrossInstances() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        do {
            let repo = BrewsLocalRepository(directory: dir)
            _ = try await repo.add(Self.makeEntry(id: "brew-persist"), photoData: Self.samplePhotoData)
        }

        let reopened = BrewsLocalRepository(directory: dir)
        let listed = try await reopened.list()
        #expect(listed.map(\.id) == ["brew-persist"])
    }
}
