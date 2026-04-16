import SwiftUI

/// Maps a `Recipe` to the bundled asset name in `Assets.xcassets/Recipes/`.
/// Uses case-insensitive substring matching on the recipe title so the
/// lookup survives different title wording (e.g. "Bedtime Lavender Tea").
/// Returns `nil` when no bundled asset exists — callers should fall back
/// to a theme-colored placeholder rectangle.
nonisolated enum RecipeImageLookup {
    private static let teaSlugs: [(match: String, slug: String)] = [
        ("chamomile", "chamomile"),
        ("peppermint", "peppermint"),
        ("ginger", "ginger"),
        ("lavender", "lavender"),
        ("lemon balm", "lemon-balm"),
        ("echinacea", "echinacea"),
        ("rooibos", "rooibos"),
        ("dandelion", "dandelion"),
    ]

    private static let tinctureSlugs: [(match: String, slug: String)] = [
        ("echinacea", "echinacea"),
        ("valerian", "valerian"),
        ("elderberry", "elderberry"),
        ("milk thistle", "milk-thistle"),
    ]

    static func assetName(for recipe: Recipe) -> String? {
        let lower = recipe.title.lowercased()
        let candidates: [(String, String)]
        let prefix: String
        switch recipe.type {
        case .tea:
            candidates = teaSlugs
            prefix = "tea-card"
        case .tincture:
            candidates = tinctureSlugs
            prefix = "tincture"
        }
        for (match, slug) in candidates where lower.contains(match) {
            return "\(prefix)-\(slug)"
        }
        return nil
    }

    static func image(for recipe: Recipe) -> Image? {
        assetName(for: recipe).map { Image($0) }
    }
}
