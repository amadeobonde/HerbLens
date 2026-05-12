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
    /// Each (title substring → imageset slug). Both herbs with bundled art (chamomile,
    /// peppermint) and herbs whose art is pending generation route to a reasonable
    /// analog — e.g. ginger falls back to the warming chamomile palette, hibiscus
    /// to the ruby tincture-prep, etc. Unmatched recipes get the scene-apothecary
    /// scene so they never render blank.
    private static let teaSlugs: [(match: String, slug: String)] = [
        ("chamomile", "TeaCardChamomile"),
        ("peppermint", "TeaCardPeppermint"),
        ("ginger", "tea_ginger"),
        ("lemon balm", "tea_lemon_balm"),
        ("rosemary", "TeaCardPeppermint"),
        ("lavender", "tea_lavender"),
        ("hibiscus", "TeaCardChamomile"),
        ("echinacea", "tea_echinacea"),
        ("dandelion", "tea_dandelion"),
        ("elderberry", "tincture_elderberry"),
        ("rooibos", "tea_rooibos"),
    ]

    private static let tinctureSlugs: [(match: String, slug: String)] = [
        ("valerian", "tincture_valerian"),
        ("milk thistle", "tincture_milk_thistle"),
        ("elderberry", "tincture_elderberry"),
        ("echinacea", "tea_echinacea"),
        ("chamomile", "TeaCardChamomile"),
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
        // Final fallback — every recipe gets a warm hero even if no herb matched.
        return "TeaCardChamomile"
    }

    static func image(for recipe: Recipe) -> Image? {
        assetName(for: recipe).map { Image("Recipes/\($0)") }
    }
}
