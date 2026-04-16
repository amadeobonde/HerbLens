import Foundation
import Testing
@testable import HerbLens

@Suite("Recipe image lookup")
struct RecipeImageLookupTests {
    private func tea(named title: String) -> Recipe {
        Recipe(
            id: "t-\(title)",
            title: title,
            type: .tea,
            difficulty: .beginner,
            prepTime: "3 min",
            steepOrCureTime: "5 min",
            yield: "1 cup",
            accessTier: .premium,
            ingredients: [],
            steps: []
        )
    }

    private func tincture(named title: String) -> Recipe {
        Recipe(
            id: "tc-\(title)",
            title: title,
            type: .tincture,
            difficulty: .intermediate,
            prepTime: "15 min",
            steepOrCureTime: "6 weeks",
            yield: "4 oz",
            accessTier: .premium,
            ingredients: [],
            steps: []
        )
    }

    @Test("each shipped tea asset resolves by title", arguments: [
        ("Classic Chamomile Sleep Tea", "tea-card-chamomile"),
        ("Fresh Peppermint Digestive Tea", "tea-card-peppermint"),
        ("Warming Ginger Root Tea", "tea-card-ginger"),
        ("Bedtime Lavender Tea", "tea-card-lavender"),
        ("Citrus Lemon Balm Tea", "tea-card-lemon-balm"),
        ("Immune Support Echinacea Tea", "tea-card-echinacea"),
        ("South African Rooibos Tea", "tea-card-rooibos"),
        ("Golden Dandelion Tea", "tea-card-dandelion"),
    ])
    func teaAssetsResolve(title: String, expected: String) {
        #expect(RecipeImageLookup.assetName(for: tea(named: title)) == expected)
    }

    @Test("each shipped tincture asset resolves by title", arguments: [
        ("Echinacea Immune Tincture", "tincture-echinacea"),
        ("Valerian Sleep Tincture", "tincture-valerian"),
        ("Elderberry Winter Tincture", "tincture-elderberry"),
        ("Milk Thistle Liver Support Tincture", "tincture-milk-thistle"),
    ])
    func tinctureAssetsResolve(title: String, expected: String) {
        #expect(RecipeImageLookup.assetName(for: tincture(named: title)) == expected)
    }

    @Test("unknown plant returns nil")
    func unknownReturnsNil() {
        #expect(RecipeImageLookup.assetName(for: tea(named: "Mystery Jungle Tea")) == nil)
        #expect(RecipeImageLookup.assetName(for: tincture(named: "Mystery Tincture")) == nil)
    }

    @Test("case insensitive matching")
    func caseInsensitive() {
        #expect(RecipeImageLookup.assetName(for: tea(named: "CHAMOMILE bedtime")) == "tea-card-chamomile")
    }
}
