import Foundation

public nonisolated enum RecipeType: String, Codable, Sendable, CaseIterable, Hashable {
    case tea
    case tincture
}

public nonisolated enum Difficulty: String, Codable, Sendable, CaseIterable, Hashable {
    case beginner
    case intermediate
    case advanced
}

public nonisolated struct RecipeIngredient: Codable, Sendable, Hashable {
    public let name: String
    public let amount: String
    public let notes: String?

    public init(name: String, amount: String, notes: String? = nil) {
        self.name = name
        self.amount = amount
        self.notes = notes
    }
}

public nonisolated struct RecipeStep: Codable, Sendable, Hashable {
    public let stepNumber: Int
    public let instruction: String
    public let tip: String?

    public init(stepNumber: Int, instruction: String, tip: String? = nil) {
        self.stepNumber = stepNumber
        self.instruction = instruction
        self.tip = tip
    }
}

public nonisolated struct Recipe: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let title: String
    public let type: RecipeType
    public let difficulty: Difficulty
    public let prepTime: String
    public let steepOrCureTime: String?
    public let yield: String
    public let accessTier: AccessTier
    public let ingredients: [RecipeIngredient]
    public let steps: [RecipeStep]
    public let imageUrl: String?

    public init(
        id: String,
        title: String,
        type: RecipeType,
        difficulty: Difficulty,
        prepTime: String,
        steepOrCureTime: String? = nil,
        yield: String,
        accessTier: AccessTier,
        ingredients: [RecipeIngredient],
        steps: [RecipeStep],
        imageUrl: String? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.difficulty = difficulty
        self.prepTime = prepTime
        self.steepOrCureTime = steepOrCureTime
        self.yield = yield
        self.accessTier = accessTier
        self.ingredients = ingredients
        self.steps = steps
        self.imageUrl = imageUrl
    }
}
