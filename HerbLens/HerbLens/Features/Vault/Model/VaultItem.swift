import Foundation

/// A single tile in the dual-section Vault grid. The Vault mixes two flows the user
/// thinks of as "their stuff": the herbs they've identified (`Scan`) and the brews
/// they've actually made (`BrewEntry`). Modeling them as one enum lets `VaultHomeView`
/// use a single grid cell type, sort/filter both sections through the same code path,
/// and render a unified detail screen via `VaultDetailView`.
///
/// Marked `nonisolated` per CLAUDE.md §10.1 — DTOs that flow across actor boundaries
/// must opt out of the project-wide `MainActor` default.
public nonisolated enum VaultItem: Sendable, Identifiable, Hashable {
    case herb(Scan)
    case brew(BrewEntry)

    public var id: String {
        switch self {
        case .herb(let scan): return "herb-\(scan.id)"
        case .brew(let brew): return "brew-\(brew.id)"
        }
    }

    /// Timestamp used for chronological sort. For Herbs it's the scan time; for Brews
    /// it's when the user logged the brew. Both flow through the same comparator so
    /// `[VaultItem].sorted(by: { $0.capturedAt > $1.capturedAt })` interleaves the
    /// two sections naturally.
    public var capturedAt: Date {
        switch self {
        case .herb(let scan): return scan.scannedAt
        case .brew(let brew): return brew.brewedAt
        }
    }

    /// Title rendered under the thumbnail. Scans don't carry a plant name on their own
    /// (the resolved `Plant` is held by the view model), so the herb side returns a
    /// generic placeholder — `VaultHomeView` overlays the resolved plant name when
    /// available.
    public var title: String {
        switch self {
        case .herb: return "Identified plant"
        case .brew(let brew): return brew.recipeTitle
        }
    }

    /// Photo URL for the grid thumbnail. Herbs return the remote `Scan.photoUrl`
    /// (loaded via `AsyncImage`); brews return the on-device file URL written by
    /// `BrewsLocalRepository` (loaded via `AsyncImage(url:)` or `Image(contentsOfFile:)`).
    public var thumbnailURL: URL? {
        switch self {
        case .herb(let scan): return URL(string: scan.photoUrl)
        case .brew(let brew): return brew.photoLocalURL
        }
    }

    /// Convenience favorite flag — only the brew side is mutable through `VaultItem`,
    /// scans expose `isFavorited` through their underlying `Scan` already.
    public var isFavorited: Bool {
        switch self {
        case .herb(let scan): return scan.isFavorited
        case .brew(let brew): return brew.isFavorited
        }
    }
}
