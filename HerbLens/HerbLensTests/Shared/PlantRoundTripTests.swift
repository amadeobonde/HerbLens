import Foundation
import Testing
@testable import HerbLens

@Suite("Plant JSON round-trip")
struct PlantRoundTripTests {
    // The sample chamomile entry from `herblens_data_structure.json` (samplePlantEntry).
    // Keep this in sync when the schema sample changes — it is the contract fixture.
    private let sampleChamomileJSON = """
    {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "commonName": "Chamomile",
      "alternateNames": ["German Chamomile", "Wild Chamomile", "Matricaria"],
      "origin": "Western Europe and Western Asia",
      "regionsFound": ["Europe", "North America", "Australia", "South America"],
      "climates": ["temperate", "mediterranean"],
      "growingConditions": "Full sun to partial shade, well-drained soil, tolerates poor soil",
      "imageUrl": "https://cdn.herblens.app/plants/chamomile.jpg",
      "thumbnailUrl": "https://cdn.herblens.app/plants/chamomile_thumb.jpg",
      "description": "A gentle, daisy-like herb prized for centuries as a natural remedy for relaxation, digestive comfort, and skin health.",
      "tags": ["calming", "digestive", "anti-inflammatory", "sleep", "skin"],
      "category": "Flower",
      "featured": true,
      "accessTier": "free",
      "healthScore": {
        "overallScore": 92,
        "goalBreakdown": [
          {
            "goalName": "Better Sleep",
            "relevanceScore": 95,
            "reason": "Contains apigenin, a compound that binds to brain receptors to promote relaxation and drowsiness."
          },
          {
            "goalName": "Stress Relief",
            "relevanceScore": 88,
            "reason": "Traditionally used to ease nervous tension. Studies show mild anxiolytic effects when consumed as tea."
          }
        ],
        "warnings": [
          {
            "type": "allergy",
            "severity": "high",
            "message": "You listed ragweed as an allergy. Chamomile is in the same plant family (Asteraceae) and may trigger a reaction."
          }
        ]
      },
      "uses": [
        {
          "category": "Nervous System",
          "description": "Widely used to promote relaxation and support restful sleep. Contains apigenin, which binds to brain receptors that reduce anxiety.",
          "accessTier": "free"
        },
        {
          "category": "Digestive",
          "description": "Soothes upset stomach, reduces bloating, and may relieve symptoms of IBS and indigestion.",
          "accessTier": "free"
        },
        {
          "category": "Skin",
          "description": "Applied topically to calm irritated skin, reduce redness, and support wound healing.",
          "accessTier": "free"
        }
      ],
      "contraindications": [
        {
          "condition": "Ragweed allergy",
          "details": "Chamomile is in the same family as ragweed. People with ragweed allergies may experience allergic reactions.",
          "severity": "high"
        },
        {
          "condition": "Blood thinners",
          "details": "Chamomile contains coumarin, which may increase the effect of anticoagulant medications.",
          "severity": "moderate"
        },
        {
          "condition": "Pregnancy",
          "details": "Large amounts may stimulate uterine contractions. Small amounts in tea are generally considered safe, but consult your doctor.",
          "severity": "moderate"
        }
      ],
      "recipes": [
        {
          "id": "r1a2b3c4-d5e6-7890-abcd-ef1234567890",
          "title": "Classic Chamomile Sleep Tea",
          "type": "tea",
          "difficulty": "beginner",
          "prepTime": "5 minutes",
          "steepOrCureTime": "5-7 minutes",
          "yield": "1 cup",
          "accessTier": "premium",
          "ingredients": [
            { "name": "Dried chamomile flowers", "amount": "1 tbsp", "notes": "Use whole flowers for best flavor" },
            { "name": "Hot water", "amount": "8 oz", "notes": "Just below boiling, around 200F" },
            { "name": "Honey", "amount": "1 tsp", "notes": "Optional, to taste" },
            { "name": "Lemon slice", "amount": "1", "notes": "Optional" }
          ],
          "steps": [
            { "stepNumber": 1, "instruction": "Place dried chamomile flowers into a tea infuser or directly into your cup.", "tip": "A mesh ball infuser works great for loose flowers." },
            { "stepNumber": 2, "instruction": "Heat water to just below boiling (about 200F / 93C).", "tip": "Boiling water can make the tea taste bitter." },
            { "stepNumber": 3, "instruction": "Pour hot water over the chamomile and let steep for 5-7 minutes.", "tip": "Longer steeping = stronger flavor and more compounds extracted." },
            { "stepNumber": 4, "instruction": "Remove the infuser or strain the flowers. Add honey and lemon if desired.", "tip": null },
            { "stepNumber": 5, "instruction": "Drink 30-60 minutes before bed for best sleep benefits.", "tip": "Make it a nightly ritual to signal your body its time to wind down." }
          ],
          "imageUrl": "https://cdn.herblens.app/recipes/chamomile_tea.jpg"
        }
      ],
      "suggestedPrompts": [
        "Can I take chamomile with melatonin?",
        "Is chamomile safe for kids?",
        "How often can I drink chamomile tea?"
      ],
      "lastUpdated": "2026-04-15T00:00:00Z"
    }
    """

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }

    @Test("decode chamomile from canonical schema sample")
    func decodeSample() throws {
        let data = Data(sampleChamomileJSON.utf8)
        let plant = try decoder.decode(Plant.self, from: data)

        #expect(plant.id == "a1b2c3d4-e5f6-7890-abcd-ef1234567890")
        #expect(plant.commonName == "Chamomile")
        #expect(plant.alternateNames.count == 3)
        #expect(plant.climates == [.temperate, .mediterranean])
        #expect(plant.featured == true)
        #expect(plant.accessTier == .free)
        #expect(plant.healthScore.overallScore == 92)
        #expect(plant.healthScore.goalBreakdown.count == 2)
        #expect(plant.healthScore.warnings.first?.type == .allergy)
        #expect(plant.healthScore.warnings.first?.severity == .high)
        #expect(plant.uses.count == 3)
        #expect(plant.contraindications.count == 3)
        #expect(plant.contraindications.last?.severity == .moderate)
        #expect(plant.recipes.count == 1)
        #expect(plant.recipes.first?.type == .tea)
        #expect(plant.recipes.first?.difficulty == .beginner)
        #expect(plant.recipes.first?.ingredients.count == 4)
        #expect(plant.recipes.first?.steps.count == 5)
        #expect(plant.recipes.first?.steps.last?.tip != nil)
        #expect(plant.suggestedPrompts.count == 3)
    }

    @Test("round-trip: decode -> encode -> decode preserves equality")
    func roundTrip() throws {
        let data = Data(sampleChamomileJSON.utf8)
        let first = try decoder.decode(Plant.self, from: data)
        let reEncoded = try encoder.encode(first)
        let second = try decoder.decode(Plant.self, from: reEncoded)

        #expect(first == second)
    }

    @Test("warning type medication_interaction decodes to camelCase enum case")
    func medicationInteractionEnum() throws {
        let json = """
        { "type": "medication_interaction", "severity": "moderate", "message": "Consult your doctor." }
        """
        let warning = try decoder.decode(Warning.self, from: Data(json.utf8))
        #expect(warning.type == .medicationInteraction)
        #expect(warning.severity == .moderate)
    }
}
