import Foundation
import Observation

@Observable
@MainActor
final class MadeRecipesStore {
    private static let defaultsKey = "recipes.made.ids"

    private let defaults: UserDefaults
    private(set) var ids: [String]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.ids = decoded
        } else {
            self.ids = []
        }
    }

    func isMade(_ recipeID: String) -> Bool {
        ids.contains(recipeID)
    }

    func toggle(_ recipeID: String) {
        if let index = ids.firstIndex(of: recipeID) {
            ids.remove(at: index)
        } else {
            ids.append(recipeID)
        }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }
}
