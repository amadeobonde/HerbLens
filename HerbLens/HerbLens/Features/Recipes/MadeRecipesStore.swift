import Foundation
import Observation

@Observable
@MainActor
final class MadeRecipesStore {
    private static let defaultsKey = "recipes.made.ids"
    private static let brewEntriesKey = "recipes.brew.entries"

    private let defaults: UserDefaults
    private(set) var ids: [String]
    /// Local persistence for `BrewEntry` stubs until Vault (Agent B3) lands a
    /// real `BrewEntriesRepository`. Re-decoded on construction so the finish
    /// flow can survive an app relaunch.
    private(set) var brewEntries: [BrewEntry]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.ids = decoded
        } else {
            self.ids = []
        }
        if let data = defaults.data(forKey: Self.brewEntriesKey),
           let decoded = try? JSONDecoder().decode([BrewEntry].self, from: data) {
            self.brewEntries = decoded
        } else {
            self.brewEntries = []
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

    /// Adds a `BrewEntry` to the local log and marks the recipe as made.
    /// Called from `RecipeFinishView` until Vault lands the real repository.
    func appendBrew(_ entry: BrewEntry) {
        brewEntries.append(entry)
        if !ids.contains(entry.recipeID) {
            ids.append(entry.recipeID)
        }
        persist()
        persistBrewEntries()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }

    private func persistBrewEntries() {
        guard let data = try? JSONEncoder().encode(brewEntries) else { return }
        defaults.set(data, forKey: Self.brewEntriesKey)
    }
}
