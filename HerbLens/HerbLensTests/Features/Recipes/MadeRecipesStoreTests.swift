import Foundation
import Testing
@testable import HerbLens

/// "Mark as made" persistence. Each test gets its own isolated UserDefaults
/// suite so toggles don't leak across cases or pollute the user's defaults.
@Suite("MadeRecipesStore")
@MainActor
struct MadeRecipesStoreTests {
    private func makeDefaults(_ suite: String = UUID().uuidString) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test("starts empty")
    func startsEmpty() {
        let store = MadeRecipesStore(defaults: makeDefaults())
        #expect(!store.isMade("r1-chamomile-tea"))
        #expect(store.ids.isEmpty)
    }

    @Test("toggle adds, toggle removes")
    func toggleCycles() {
        let store = MadeRecipesStore(defaults: makeDefaults())
        store.toggle("r1-chamomile-tea")
        #expect(store.isMade("r1-chamomile-tea"))
        store.toggle("r1-chamomile-tea")
        #expect(!store.isMade("r1-chamomile-tea"))
    }

    @Test("persists across instance re-creation")
    func persistsAcrossInstances() {
        let suite = "persist-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let first = MadeRecipesStore(defaults: defaults)
        first.toggle("r2-peppermint-tea")
        first.toggle("r-tincture-echinacea")

        let second = MadeRecipesStore(defaults: defaults)
        #expect(second.isMade("r2-peppermint-tea"))
        #expect(second.isMade("r-tincture-echinacea"))
        #expect(!second.isMade("r1-chamomile-tea"))
    }

    @Test("multiple recipe IDs are independent")
    func independentIDs() {
        let store = MadeRecipesStore(defaults: makeDefaults())
        store.toggle("a")
        store.toggle("b")
        store.toggle("c")
        store.toggle("b")
        #expect(store.isMade("a"))
        #expect(!store.isMade("b"))
        #expect(store.isMade("c"))
    }
}
