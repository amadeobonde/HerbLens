import SwiftUI
import UIKit

/// Resolves a `HighlightCollection` to its cover artwork. First tries the bundled
/// imageset under `Assets.xcassets/Collections/<PascalSlug>.imageset`; falls back to
/// a tinted SF Symbol so the row still renders even when an asset hasn't shipped yet
/// (per plan: any collection cover that fails the strict review is discarded and
/// served by the fallback).
public nonisolated enum HomeCollectionCoverProvider {
    /// Maps a collection's slug-form ID (e.g. "collection-sleep-aids") to its
    /// PascalCased asset name (e.g. "SleepAids"). Returns `nil` for unknown slugs.
    static let assetNamesBySlug: [String: String] = [
        "collection-sleep-aids": "SleepAids",
        "collection-digestive-support": "DigestiveSupport",
        "collection-stress-relief": "StressRelief",
        "collection-immunity": "Immunity",
        "collection-skin": "Skin",
        "collection-energy": "Energy",
        "collection-focus": "Focus",
        "collection-womens-health": "WomensHealth",
    ]

    /// Returns a SwiftUI `Image` for the given collection. Prefers the bundled
    /// imageset; falls back to an SF Symbol if the asset is missing.
    @MainActor
    public static func image(for collection: HighlightCollection) -> Image {
        if let assetName = assetNamesBySlug[collection.id],
           UIImage(named: assetName) != nil {
            return Image(assetName)
        }
        return Image(systemName: fallbackSymbol(for: collection.id))
    }

    /// Symbol used when the imageset is missing. Picked to roughly match each
    /// collection's theme so the fallback still feels intentional.
    static func fallbackSymbol(for slug: String) -> String {
        switch slug {
        case "collection-sleep-aids": return "moon.stars.fill"
        case "collection-digestive-support": return "leaf.fill"
        case "collection-stress-relief": return "wind"
        case "collection-immunity": return "shield.lefthalf.filled"
        case "collection-skin": return "sparkles"
        case "collection-energy": return "sun.max.fill"
        case "collection-focus": return "brain.head.profile"
        case "collection-womens-health": return "heart.fill"
        default: return "leaf.circle.fill"
        }
    }
}
