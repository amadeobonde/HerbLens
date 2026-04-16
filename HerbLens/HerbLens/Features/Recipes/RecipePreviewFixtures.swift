import Foundation

/// Recipe fixtures for SwiftUI previews. Combines tea recipes already embedded
/// on `SampleData.plants` with four hand-coded tinctures so the browse UI can
/// render both sections before Instance 2 seeds tinctures into SampleData.
nonisolated enum RecipePreviewFixtures {
    static var teas: [Recipe] {
        SampleData.plants.flatMap(\.recipes).filter { $0.type == .tea }
    }

    static var localTinctures: [Recipe] {
        [echinaceaTincture, valerianTincture, elderberryTincture, milkThistleTincture]
    }

    static var allRecipes: [Recipe] {
        teas + localTinctures
    }

    static var echinaceaTincture: Recipe {
        Recipe(
            id: "r-tincture-echinacea",
            title: "Echinacea Immune Tincture",
            type: .tincture,
            difficulty: .intermediate,
            prepTime: "15 minutes",
            steepOrCureTime: "4-6 weeks",
            yield: "4 oz",
            accessTier: .premium,
            ingredients: [
                RecipeIngredient(name: "Dried echinacea root", amount: "1 cup", notes: "Chopped"),
                RecipeIngredient(name: "Vodka (40% / 80 proof)", amount: "16 oz", notes: "Covers the herb by 2 inches"),
            ],
            steps: [
                RecipeStep(stepNumber: 1, instruction: "Fill a clean pint jar halfway with chopped root.", tip: "Leave headroom — the root swells."),
                RecipeStep(stepNumber: 2, instruction: "Pour vodka until the root is submerged by 2 inches.", tip: nil),
                RecipeStep(stepNumber: 3, instruction: "Cap, label with date, and store in a cool dark cupboard.", tip: nil),
                RecipeStep(stepNumber: 4, instruction: "Shake daily for 4-6 weeks.", tip: "A daily shake is the whole technique."),
                RecipeStep(stepNumber: 5, instruction: "Strain through cheesecloth into dropper bottles.", tip: "Squeeze the spent herb — that's the strongest liquid."),
            ],
            imageUrl: nil
        )
    }

    static var valerianTincture: Recipe {
        Recipe(
            id: "r-tincture-valerian",
            title: "Valerian Sleep Tincture",
            type: .tincture,
            difficulty: .intermediate,
            prepTime: "15 minutes",
            steepOrCureTime: "4-6 weeks",
            yield: "4 oz",
            accessTier: .premium,
            ingredients: [
                RecipeIngredient(name: "Dried valerian root", amount: "1 cup", notes: "Pungent — open a window"),
                RecipeIngredient(name: "Vodka (40% / 80 proof)", amount: "16 oz", notes: nil),
            ],
            steps: [
                RecipeStep(stepNumber: 1, instruction: "Pack chopped root into a pint jar.", tip: nil),
                RecipeStep(stepNumber: 2, instruction: "Cover with vodka to 2 inches above the herb.", tip: nil),
                RecipeStep(stepNumber: 3, instruction: "Shake daily for 4-6 weeks.", tip: nil),
                RecipeStep(stepNumber: 4, instruction: "Strain and bottle.", tip: "30-60 drops under the tongue, 30 min before bed."),
            ],
            imageUrl: nil
        )
    }

    static var elderberryTincture: Recipe {
        Recipe(
            id: "r-tincture-elderberry",
            title: "Elderberry Winter Tincture",
            type: .tincture,
            difficulty: .beginner,
            prepTime: "10 minutes",
            steepOrCureTime: "4 weeks",
            yield: "4 oz",
            accessTier: .premium,
            ingredients: [
                RecipeIngredient(name: "Dried elderberries", amount: "1 cup", notes: "Raw berries MUST be cooked — use dried"),
                RecipeIngredient(name: "Vodka (40% / 80 proof)", amount: "16 oz", notes: nil),
            ],
            steps: [
                RecipeStep(stepNumber: 1, instruction: "Place berries in a pint jar.", tip: nil),
                RecipeStep(stepNumber: 2, instruction: "Cover with vodka by 2 inches.", tip: nil),
                RecipeStep(stepNumber: 3, instruction: "Shake daily for 4 weeks.", tip: nil),
                RecipeStep(stepNumber: 4, instruction: "Strain through cheesecloth.", tip: "1 tsp at first sniffle, repeat up to 3x/day."),
            ],
            imageUrl: nil
        )
    }

    static var milkThistleTincture: Recipe {
        Recipe(
            id: "r-tincture-milk-thistle",
            title: "Milk Thistle Liver Support Tincture",
            type: .tincture,
            difficulty: .intermediate,
            prepTime: "20 minutes",
            steepOrCureTime: "6 weeks",
            yield: "4 oz",
            accessTier: .premium,
            ingredients: [
                RecipeIngredient(name: "Milk thistle seeds", amount: "1/2 cup", notes: "Ground in a coffee grinder"),
                RecipeIngredient(name: "Vodka (40% / 80 proof)", amount: "16 oz", notes: nil),
            ],
            steps: [
                RecipeStep(stepNumber: 1, instruction: "Grind seeds to a coarse meal.", tip: "Silymarin is bound in the seed hull — grinding unlocks it."),
                RecipeStep(stepNumber: 2, instruction: "Place in a pint jar and cover with vodka.", tip: nil),
                RecipeStep(stepNumber: 3, instruction: "Shake daily for 6 weeks.", tip: nil),
                RecipeStep(stepNumber: 4, instruction: "Strain through coffee filter — twice if silt persists.", tip: "30 drops in water before meals."),
            ],
            imageUrl: nil
        )
    }
}
