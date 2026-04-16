import Foundation
import Testing
@testable import HerbLens

@Suite("Recipe preview fixtures")
struct RecipePreviewFixturesTests {
    @Test("allRecipes contains teas from SampleData plus local tinctures")
    func allRecipesIncludesBothKinds() {
        let all = RecipePreviewFixtures.allRecipes
        let teas = all.filter { $0.type == .tea }
        let tinctures = all.filter { $0.type == .tincture }
        #expect(teas.count >= 5)            // chamomile, peppermint, ginger, lavender, echinacea
        #expect(tinctures.count == 4)        // echinacea, valerian, elderberry, milk-thistle
    }

    @Test("every local tincture has a shipped asset")
    func tincturesHaveAssets() {
        for tincture in RecipePreviewFixtures.localTinctures {
            #expect(RecipeImageLookup.assetName(for: tincture) != nil,
                    "Missing asset for \(tincture.title)")
        }
    }

    @Test("every tincture is premium")
    func tincturesAreAllPremium() {
        for tincture in RecipePreviewFixtures.localTinctures {
            #expect(tincture.accessTier == .premium)
        }
    }

    @Test("every tincture has a weeks-scale cure")
    func tincturesHaveWeekCure() {
        for tincture in RecipePreviewFixtures.localTinctures {
            let raw = tincture.steepOrCureTime ?? ""
            #expect(raw.lowercased().contains("week"))
            #expect(SteepDurationParser.minutes(from: tincture.steepOrCureTime) == nil)
        }
    }

    @Test("every tea has a parseable steep minute")
    func teasHaveSteepMinutes() {
        for tea in RecipePreviewFixtures.teas {
            let minutes = SteepDurationParser.minutes(from: tea.steepOrCureTime)
            #expect(minutes != nil, "Tea '\(tea.title)' has unparseable steep: \(tea.steepOrCureTime ?? "nil")")
        }
    }
}
