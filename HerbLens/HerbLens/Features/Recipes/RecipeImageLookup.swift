import SwiftUI

/// Maps a `Recipe` to a bundled asset under `Assets.xcassets/Recipes/`.
/// Returns the asset name *without* the `Recipes/` prefix — callers prepend
/// `Recipes/` when they need a fully-qualified path. Falls back to `nil`
/// when no bundled asset exists; callers render a theme-coloured placeholder.
///
/// Asset names match the design-system `Recipes/` imagesets (CamelCase, e.g.
/// `Recipes/TeaCardChamomile`). When new bundled tea cards land, append a
/// `(match, slug)` row here and ship the matching imageset alongside.
nonisolated enum RecipeImageLookup {
    private static let teaSlugs: [(match: String, slug: String)] = [
        ("chamomile", "TeaCardChamomile"),
        ("peppermint", "TeaCardPeppermint"),
        // Future tea cards (ginger, lavender, lemon balm, echinacea, rooibos,
        // dandelion) — wire as soon as the matching `Recipes/TeaCardX.imageset`
        // ships in `Assets.xcassets`.
    ]

    private static let tinctureSlugs: [(match: String, slug: String)] = [
        // No bundled tincture asset shipped yet — placeholder rendering kicks in.
    ]

    /// Returns the bare asset slug (e.g. `TeaCardChamomile`) or `nil`. Callers
    /// that want a fully-qualified `Recipes/Slug` path build it themselves.
    static func assetName(for recipe: Recipe) -> String? {
        let lower = recipe.title.lowercased()
        let candidates: [(String, String)]
        switch recipe.type {
        case .tea:       candidates = teaSlugs
        case .tincture:  candidates = tinctureSlugs
        }
        for (match, slug) in candidates where lower.contains(match) {
            return slug
        }
        return nil
    }

    static func image(for recipe: Recipe) -> Image? {
        assetName(for: recipe).map { Image("Recipes/\($0)") }
    }
}
