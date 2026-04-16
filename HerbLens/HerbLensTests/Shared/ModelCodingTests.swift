import Foundation
import Testing
@testable import HerbLens

@Suite("Model JSON coding")
struct ModelCodingTests {
    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }

    @Test("UserProfile decodes with nested HealthProfile")
    func userProfile() throws {
        let json = """
        {
          "id": "u1",
          "email": "a@b.com",
          "displayName": "A",
          "avatarUrl": null,
          "subscriptionTier": "premium",
          "createdAt": "2026-04-15T00:00:00Z",
          "updatedAt": "2026-04-15T00:00:00Z",
          "onboardingCompleted": true,
          "healthProfile": {
            "goals": [
              { "id": "g1", "name": "Better Sleep", "priority": 1, "addedAt": "2026-04-15T00:00:00Z" }
            ],
            "allergies": ["ragweed"],
            "medications": null,
            "conditions": null,
            "experienceLevel": "intermediate"
          }
        }
        """
        let user = try decoder.decode(UserProfile.self, from: Data(json.utf8))
        #expect(user.subscriptionTier == .premium)
        #expect(user.onboardingCompleted == true)
        #expect(user.healthProfile.experienceLevel == .intermediate)
        #expect(user.healthProfile.goals.first?.priority == 1)
        #expect(user.avatarUrl == nil)
    }

    @Test("Scan decodes")
    func scan() throws {
        let json = """
        {
          "id": "s1",
          "userId": "u1",
          "photoUrl": "https://x/y.jpg",
          "scannedAt": "2026-04-15T00:00:00Z",
          "identifiedPlantId": "p1",
          "confidenceScore": 0.92,
          "userNotes": null,
          "isFavorited": true,
          "healthScoreAtScan": 88,
          "accessTier": "free"
        }
        """
        let scan = try decoder.decode(Scan.self, from: Data(json.utf8))
        #expect(scan.confidenceScore == 0.92)
        #expect(scan.isFavorited == true)
        #expect(scan.accessTier == .free)
    }

    @Test("HighlightCollection decodes")
    func highlight() throws {
        let json = """
        {
          "id": "c1",
          "title": "Sleep Aids",
          "subtitle": "Wind down",
          "coverImageUrl": "https://x/y.jpg",
          "plantIds": ["p1", "p2"],
          "displayOrder": 0,
          "accessTier": "free"
        }
        """
        let c = try decoder.decode(HighlightCollection.self, from: Data(json.utf8))
        #expect(c.plantIds.count == 2)
    }

    @Test("Conversation decodes with nested Messages")
    func conversation() throws {
        let json = """
        {
          "id": "c1",
          "userId": "u1",
          "startedAt": "2026-04-15T00:00:00Z",
          "lastMessageAt": "2026-04-15T00:01:00Z",
          "contextPlantId": null,
          "messages": [
            { "id": "m1", "role": "user", "content": "hi", "timestamp": "2026-04-15T00:00:00Z" },
            { "id": "m2", "role": "assistant", "content": "hello", "timestamp": "2026-04-15T00:01:00Z" }
          ]
        }
        """
        let c = try decoder.decode(Conversation.self, from: Data(json.utf8))
        #expect(c.messages.count == 2)
        #expect(c.messages[0].role == .user)
        #expect(c.messages[1].role == .assistant)
        #expect(c.contextPlantId == nil)
    }

    @Test("HealthScore decodes")
    func healthScore() throws {
        let json = """
        {
          "overallScore": 75,
          "goalBreakdown": [
            { "goalName": "Focus", "relevanceScore": 80, "reason": "alpha boost" }
          ],
          "warnings": []
        }
        """
        let h = try decoder.decode(HealthScore.self, from: Data(json.utf8))
        #expect(h.overallScore == 75)
        #expect(h.goalBreakdown.first?.goalName == "Focus")
        #expect(h.warnings.isEmpty)
    }

    @Test("Recipe decodes both tea and tincture types",
          arguments: [
            (#"{"id":"r1","title":"T","type":"tea","difficulty":"beginner","prepTime":"5","steepOrCureTime":"5","yield":"1","accessTier":"premium","ingredients":[],"steps":[],"imageUrl":null}"#, RecipeType.tea),
            (#"{"id":"r2","title":"T","type":"tincture","difficulty":"advanced","prepTime":"15","steepOrCureTime":"4 weeks","yield":"4oz","accessTier":"premium","ingredients":[],"steps":[],"imageUrl":null}"#, RecipeType.tincture),
          ] as [(String, RecipeType)])
    func recipeVariants(json: String, expected: RecipeType) throws {
        let recipe = try decoder.decode(Recipe.self, from: Data(json.utf8))
        #expect(recipe.type == expected)
    }
}
