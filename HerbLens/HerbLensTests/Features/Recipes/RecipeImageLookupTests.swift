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

    @Test("shipped tea assets resolve by title", arguments: [
        ("Classic Chamomile Sleep Tea", "TeaCardChamomile"),
        ("Fresh Peppermint Digestive Tea", "TeaCardPeppermint"),
    ])
    func teaAssetsResolve(title: String, expected: String) {
        #expect(RecipeImageLookup.assetName(for: tea(named: title)) == expected)
    }

    @Test("teas without a bundled card return nil", arguments: [
        "Warming Ginger Root Tea",
        "Bedtime Lavender Tea",
        "Citrus Lemon Balm Tea",
    ])
    func unbundledTeasReturnNil(title: String) {
        #expect(RecipeImageLookup.assetName(for: tea(named: title)) == nil)
    }

    @Test("tinctures currently have no bundled assets", arguments: [
        "Echinacea Immune Tincture",
        "Valerian Sleep Tincture",
        "Elderberry Winter Tincture",
        "Milk Thistle Liver Support Tincture",
    ])
    func tincturesReturnNil(title: String) {
        #expect(RecipeImageLookup.assetName(for: tincture(named: title)) == nil)
    }

    @Test("unknown plant returns nil")
    func unknownReturnsNil() {
        #expect(RecipeImageLookup.assetName(for: tea(named: "Mystery Jungle Tea")) == nil)
        #expect(RecipeImageLookup.assetName(for: tincture(named: "Mystery Tincture")) == nil)
    }

    @Test("case insensitive matching")
    func caseInsensitive() {
        #expect(RecipeImageLookup.assetName(for: tea(named: "CHAMOMILE bedtime")) == "TeaCardChamomile")
    }
}
