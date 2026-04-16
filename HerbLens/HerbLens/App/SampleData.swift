import Foundation

/// Canned sample data used by `AppDependencies.mock` and SwiftUI `#Preview` blocks.
/// Values mirror the `samplePlantEntry` in `herblens_data_structure.json` so previews
/// look realistic and JSON round-trip tests have something to pin against.
nonisolated enum SampleData {
    static let userID = "00000000-0000-0000-0000-000000000001"

    static var healthProfile: HealthProfile {
        HealthProfile(
            goals: [
                HealthGoal(
                    id: "goal-1",
                    name: "Better Sleep",
                    priority: 1,
                    addedAt: Date(timeIntervalSince1970: 1_700_000_000)
                ),
                HealthGoal(
                    id: "goal-2",
                    name: "Stress Relief",
                    priority: 2,
                    addedAt: Date(timeIntervalSince1970: 1_700_000_000)
                ),
            ],
            allergies: ["ragweed"],
            medications: nil,
            conditions: nil,
            experienceLevel: .beginner
        )
    }

    static var userProfile: UserProfile {
        UserProfile(
            id: userID,
            email: "preview@herblens.app",
            displayName: "Preview User",
            avatarUrl: nil,
            subscriptionTier: .free,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            onboardingCompleted: true,
            healthProfile: healthProfile
        )
    }

    static var chamomile: Plant {
        Plant(
            id: "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            commonName: "Chamomile",
            alternateNames: ["German Chamomile", "Wild Chamomile", "Matricaria"],
            origin: "Western Europe and Western Asia",
            regionsFound: ["Europe", "North America", "Australia", "South America"],
            climates: [.temperate, .mediterranean],
            growingConditions: "Full sun to partial shade, well-drained soil, tolerates poor soil",
            imageUrl: "https://cdn.herblens.app/plants/chamomile.jpg",
            thumbnailUrl: "https://cdn.herblens.app/plants/chamomile_thumb.jpg",
            description: "A gentle, daisy-like herb prized for centuries as a natural remedy for relaxation, digestive comfort, and skin health.",
            tags: ["calming", "digestive", "anti-inflammatory", "sleep", "skin"],
            category: "Flower",
            featured: true,
            accessTier: .free,
            healthScore: HealthScore(
                overallScore: 92,
                goalBreakdown: [
                    GoalBreakdown(
                        goalName: "Better Sleep",
                        relevanceScore: 95,
                        reason: "Contains apigenin, a compound that binds to brain receptors to promote relaxation and drowsiness."
                    ),
                    GoalBreakdown(
                        goalName: "Stress Relief",
                        relevanceScore: 88,
                        reason: "Traditionally used to ease nervous tension. Studies show mild anxiolytic effects when consumed as tea."
                    ),
                ],
                warnings: [
                    Warning(
                        type: .allergy,
                        severity: .high,
                        message: "You listed ragweed as an allergy. Chamomile is in the same plant family (Asteraceae) and may trigger a reaction."
                    ),
                ]
            ),
            uses: [
                PlantUse(
                    category: "Nervous System",
                    description: "Widely used to promote relaxation and support restful sleep.",
                    accessTier: .free
                ),
                PlantUse(
                    category: "Digestive",
                    description: "Soothes upset stomach, reduces bloating.",
                    accessTier: .free
                ),
            ],
            contraindications: [
                Contraindication(
                    condition: "Ragweed allergy",
                    details: "Chamomile is in the same family as ragweed.",
                    severity: .high
                ),
            ],
            recipes: [
                Recipe(
                    id: "r1a2b3c4-d5e6-7890-abcd-ef1234567890",
                    title: "Classic Chamomile Sleep Tea",
                    type: .tea,
                    difficulty: .beginner,
                    prepTime: "5 minutes",
                    steepOrCureTime: "5-7 minutes",
                    yield: "1 cup",
                    accessTier: .premium,
                    ingredients: [
                        RecipeIngredient(name: "Dried chamomile flowers", amount: "1 tbsp", notes: nil),
                        RecipeIngredient(name: "Hot water", amount: "8 oz", notes: "Just below boiling"),
                    ],
                    steps: [
                        RecipeStep(stepNumber: 1, instruction: "Steep the flowers 5-7 minutes.", tip: nil),
                    ],
                    imageUrl: nil
                ),
            ],
            suggestedPrompts: [
                "Can I take chamomile with melatonin?",
                "Is chamomile safe for kids?",
            ],
            lastUpdated: Date(timeIntervalSince1970: 1_744_243_200)
        )
    }

    static var highlightCollection: HighlightCollection {
        HighlightCollection(
            id: "coll-1",
            title: "Sleep Aids",
            subtitle: "Plants to help you wind down naturally",
            coverImageUrl: "https://cdn.herblens.app/collections/sleep.jpg",
            plantIds: [chamomile.id],
            displayOrder: 0,
            accessTier: .free
        )
    }

    static var conversation: Conversation {
        Conversation(
            id: "conv-1",
            userId: userID,
            startedAt: Date(timeIntervalSince1970: 1_744_243_200),
            lastMessageAt: Date(timeIntervalSince1970: 1_744_243_260),
            contextPlantId: chamomile.id,
            messages: [
                Message(
                    id: "msg-1",
                    role: .user,
                    content: "Is chamomile safe with blood thinners?",
                    timestamp: Date(timeIntervalSince1970: 1_744_243_200)
                ),
                Message(
                    id: "msg-2",
                    role: .assistant,
                    content: "Chamomile contains coumarin which may enhance anticoagulant effects. Consult your doctor.",
                    timestamp: Date(timeIntervalSince1970: 1_744_243_260)
                ),
            ]
        )
    }

    static var scan: Scan {
        Scan(
            id: "scan-1",
            userId: userID,
            photoUrl: "https://cdn.herblens.app/scans/demo.jpg",
            scannedAt: Date(timeIntervalSince1970: 1_744_243_200),
            identifiedPlantId: chamomile.id,
            confidenceScore: 0.94,
            userNotes: nil,
            isFavorited: true,
            healthScoreAtScan: 92,
            accessTier: .free
        )
    }

    static var offerings: [Offering] {
        [
            Offering(
                id: "offer-monthly",
                packageID: "herblens_pro_monthly",
                displayName: "HerbLens Pro — Monthly",
                priceString: "$4.99 / mo",
                tier: .premium,
                periodDescription: "Renews monthly",
                trialDays: 7
            ),
            Offering(
                id: "offer-yearly",
                packageID: "herblens_pro_yearly",
                displayName: "HerbLens Pro — Yearly",
                priceString: "$39.99 / yr",
                tier: .premium,
                periodDescription: "Renews yearly",
                trialDays: 7
            ),
        ]
    }
}
