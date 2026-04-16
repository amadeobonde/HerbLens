import Foundation

/// Canned sample data used by `AppDependencies.mock` and SwiftUI `#Preview` blocks.
/// Values mirror the `samplePlantEntry` in `herblens_data_structure.json` so previews
/// look realistic and JSON round-trip tests have something to pin against.
///
/// Instance 2 expanded the seed from 1 → 5 plants (chamomile, peppermint, ginger,
/// lavender, echinacea) so Vault, Home, and Search screens have variety in Previews.
nonisolated enum SampleData {
    static let userID = "00000000-0000-0000-0000-000000000001"

    // MARK: - Profile

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

    // MARK: - Plants

    static var plants: [Plant] { [chamomile, peppermint, ginger, lavender, echinacea] }

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
                PlantUse(category: "Nervous System", description: "Widely used to promote relaxation and support restful sleep.", accessTier: .free),
                PlantUse(category: "Digestive", description: "Soothes upset stomach, reduces bloating.", accessTier: .free),
            ],
            contraindications: [
                Contraindication(condition: "Ragweed allergy", details: "Chamomile is in the same family as ragweed.", severity: .high),
            ],
            recipes: [
                Recipe(
                    id: "r1-chamomile-tea",
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

    static var peppermint: Plant {
        Plant(
            id: "b2c3d4e5-f678-9012-bcde-f23456789012",
            commonName: "Peppermint",
            alternateNames: ["Mentha × piperita", "Brandy Mint"],
            origin: "Europe and the Middle East",
            regionsFound: ["Europe", "North America", "Asia", "Australia"],
            climates: [.temperate, .mediterranean],
            growingConditions: "Moist soil, partial shade, spreads aggressively via runners.",
            imageUrl: "https://cdn.herblens.app/plants/peppermint.jpg",
            thumbnailUrl: "https://cdn.herblens.app/plants/peppermint_thumb.jpg",
            description: "A cooling aromatic herb rich in menthol, used for digestive relief, headache ease, and sinus support.",
            tags: ["digestive", "cooling", "respiratory", "headache", "energizing"],
            category: "Herb",
            featured: true,
            accessTier: .free,
            healthScore: HealthScore(
                overallScore: 84,
                goalBreakdown: [
                    GoalBreakdown(goalName: "Better Sleep", relevanceScore: 45, reason: "Mildly stimulating; avoid right before bed."),
                    GoalBreakdown(goalName: "Stress Relief", relevanceScore: 72, reason: "Menthol's cooling aroma eases tension headaches and stress-related nausea."),
                ],
                warnings: []
            ),
            uses: [
                PlantUse(category: "Digestive", description: "Relaxes GI smooth muscle — classic remedy for IBS-type cramping and bloating.", accessTier: .free),
                PlantUse(category: "Respiratory", description: "Menthol opens sinuses; helpful in steam inhalation for congestion.", accessTier: .free),
            ],
            contraindications: [
                Contraindication(condition: "GERD / acid reflux", details: "Peppermint relaxes the lower esophageal sphincter and can worsen reflux.", severity: .moderate),
                Contraindication(condition: "Infants under 2", details: "Menthol can cause breathing difficulty in young children.", severity: .high),
            ],
            recipes: [
                Recipe(
                    id: "r2-peppermint-tea",
                    title: "Fresh Peppermint Digestive Tea",
                    type: .tea,
                    difficulty: .beginner,
                    prepTime: "3 minutes",
                    steepOrCureTime: "5 minutes",
                    yield: "1 cup",
                    accessTier: .premium,
                    ingredients: [
                        RecipeIngredient(name: "Fresh peppermint leaves", amount: "10 leaves", notes: "Bruise gently to release oils"),
                        RecipeIngredient(name: "Hot water", amount: "8 oz", notes: nil),
                    ],
                    steps: [
                        RecipeStep(stepNumber: 1, instruction: "Bruise the leaves in a mug.", tip: "A pestle or the back of a spoon works."),
                        RecipeStep(stepNumber: 2, instruction: "Pour hot water and steep 5 minutes.", tip: nil),
                    ],
                    imageUrl: nil
                ),
            ],
            suggestedPrompts: [
                "Can peppermint help with IBS?",
                "Is peppermint tea safe while pregnant?",
            ],
            lastUpdated: Date(timeIntervalSince1970: 1_744_243_200)
        )
    }

    static var ginger: Plant {
        Plant(
            id: "c3d4e5f6-7890-1234-cdef-345678901234",
            commonName: "Ginger",
            alternateNames: ["Zingiber officinale"],
            origin: "Maritime Southeast Asia",
            regionsFound: ["Asia", "Africa", "Caribbean", "South America"],
            climates: [.tropical, .subtropical],
            growingConditions: "Warm, humid climate; rich, well-drained soil; partial shade.",
            imageUrl: "https://cdn.herblens.app/plants/ginger.jpg",
            thumbnailUrl: "https://cdn.herblens.app/plants/ginger_thumb.jpg",
            description: "A pungent rhizome celebrated as a nausea remedy, digestive warmer, and anti-inflammatory staple across global traditions.",
            tags: ["digestive", "anti-inflammatory", "warming", "nausea", "immune"],
            category: "Root",
            featured: true,
            accessTier: .free,
            healthScore: HealthScore(
                overallScore: 89,
                goalBreakdown: [
                    GoalBreakdown(goalName: "Better Sleep", relevanceScore: 35, reason: "Warming but stimulating — minor role in sleep support."),
                    GoalBreakdown(goalName: "Stress Relief", relevanceScore: 60, reason: "Anti-inflammatory effects indirectly reduce somatic stress load."),
                ],
                warnings: [
                    Warning(type: .medicationInteraction, severity: .moderate, message: "May amplify blood thinners (warfarin, aspirin). Use caution if on anticoagulants."),
                ]
            ),
            uses: [
                PlantUse(category: "Digestive", description: "Reduces nausea — well-documented for motion sickness and morning sickness.", accessTier: .free),
                PlantUse(category: "Anti-inflammatory", description: "Gingerols inhibit COX-2; eases joint and muscle pain.", accessTier: .free),
            ],
            contraindications: [
                Contraindication(condition: "Blood thinners", details: "Potentiates anticoagulant medications.", severity: .moderate),
                Contraindication(condition: "Gallstones", details: "Stimulates bile production — consult a clinician.", severity: .moderate),
            ],
            recipes: [
                Recipe(
                    id: "r3-ginger-tea",
                    title: "Warming Ginger Root Tea",
                    type: .tea,
                    difficulty: .beginner,
                    prepTime: "8 minutes",
                    steepOrCureTime: "10 minutes",
                    yield: "1 cup",
                    accessTier: .premium,
                    ingredients: [
                        RecipeIngredient(name: "Fresh ginger root", amount: "1 inch", notes: "Sliced thin"),
                        RecipeIngredient(name: "Hot water", amount: "10 oz", notes: nil),
                        RecipeIngredient(name: "Honey", amount: "1 tsp", notes: "Optional"),
                    ],
                    steps: [
                        RecipeStep(stepNumber: 1, instruction: "Simmer sliced ginger in water 10 minutes.", tip: "Longer simmer → more pungent."),
                        RecipeStep(stepNumber: 2, instruction: "Strain and stir in honey.", tip: nil),
                    ],
                    imageUrl: nil
                ),
            ],
            suggestedPrompts: [
                "How much ginger for morning sickness?",
                "Ginger vs. turmeric — which is stronger anti-inflammatory?",
            ],
            lastUpdated: Date(timeIntervalSince1970: 1_744_243_200)
        )
    }

    static var lavender: Plant {
        Plant(
            id: "d4e5f678-9012-3456-def0-456789012345",
            commonName: "Lavender",
            alternateNames: ["Lavandula angustifolia", "English Lavender"],
            origin: "Mediterranean basin",
            regionsFound: ["Europe", "North America", "Australia"],
            climates: [.mediterranean, .temperate],
            growingConditions: "Full sun, well-drained sandy soil, low water once established.",
            imageUrl: "https://cdn.herblens.app/plants/lavender.jpg",
            thumbnailUrl: "https://cdn.herblens.app/plants/lavender_thumb.jpg",
            description: "A fragrant purple-flowered herb long used to promote calm, restful sleep, and skin healing.",
            tags: ["calming", "sleep", "aromatic", "skin", "anxiolytic"],
            category: "Flower",
            featured: false,
            accessTier: .free,
            healthScore: HealthScore(
                overallScore: 90,
                goalBreakdown: [
                    GoalBreakdown(goalName: "Better Sleep", relevanceScore: 92, reason: "Linalool and linalyl acetate have documented sedative effects via GABA pathways."),
                    GoalBreakdown(goalName: "Stress Relief", relevanceScore: 90, reason: "Randomized trials support anxiolytic action of oral lavender oil (Silexan)."),
                ],
                warnings: []
            ),
            uses: [
                PlantUse(category: "Nervous System", description: "Eases anxiety and supports sleep onset.", accessTier: .free),
                PlantUse(category: "Skin", description: "Topical infusion calms minor burns and insect bites.", accessTier: .free),
            ],
            contraindications: [
                Contraindication(condition: "Pregnancy (internal use)", details: "Internal use not recommended during pregnancy.", severity: .moderate),
            ],
            recipes: [
                Recipe(
                    id: "r4-lavender-tea",
                    title: "Bedtime Lavender Tea",
                    type: .tea,
                    difficulty: .beginner,
                    prepTime: "4 minutes",
                    steepOrCureTime: "7 minutes",
                    yield: "1 cup",
                    accessTier: .premium,
                    ingredients: [
                        RecipeIngredient(name: "Dried lavender buds", amount: "1 tsp", notes: "Culinary grade only"),
                        RecipeIngredient(name: "Hot water", amount: "8 oz", notes: nil),
                    ],
                    steps: [
                        RecipeStep(stepNumber: 1, instruction: "Steep buds 7 minutes — longer turns bitter.", tip: "Cover while steeping to trap aromatics."),
                    ],
                    imageUrl: nil
                ),
            ],
            suggestedPrompts: [
                "Can I take lavender with sleep medication?",
                "Is lavender essential oil safe to ingest?",
            ],
            lastUpdated: Date(timeIntervalSince1970: 1_744_243_200)
        )
    }

    static var echinacea: Plant {
        Plant(
            id: "e5f67890-1234-5678-ef01-567890123456",
            commonName: "Echinacea",
            alternateNames: ["Purple Coneflower", "Echinacea purpurea"],
            origin: "Central and eastern North America",
            regionsFound: ["North America", "Europe"],
            climates: [.temperate],
            growingConditions: "Full sun, average to dry soil, drought-tolerant once established.",
            imageUrl: "https://cdn.herblens.app/plants/echinacea.jpg",
            thumbnailUrl: "https://cdn.herblens.app/plants/echinacea_thumb.jpg",
            description: "A native North American flower used traditionally to shorten the duration of common colds and support immune resilience.",
            tags: ["immune", "cold-season", "anti-inflammatory"],
            category: "Flower",
            featured: false,
            accessTier: .free,
            healthScore: HealthScore(
                overallScore: 78,
                goalBreakdown: [
                    GoalBreakdown(goalName: "Better Sleep", relevanceScore: 20, reason: "Not a primary sleep aid."),
                    GoalBreakdown(goalName: "Stress Relief", relevanceScore: 40, reason: "Adaptogen-adjacent; limited direct evidence for stress."),
                ],
                warnings: [
                    Warning(type: .allergy, severity: .high, message: "Ragweed-family allergy — same Asteraceae family as chamomile."),
                    Warning(type: .condition, severity: .moderate, message: "Autoimmune conditions — echinacea stimulates T-cell activity."),
                ]
            ),
            uses: [
                PlantUse(category: "Immune", description: "Taken at onset of cold/flu symptoms to shorten duration.", accessTier: .free),
                PlantUse(category: "Anti-inflammatory", description: "Topical preparations for minor wound support.", accessTier: .free),
            ],
            contraindications: [
                Contraindication(condition: "Autoimmune disease", details: "May over-activate immune response.", severity: .high),
                Contraindication(condition: "Asteraceae allergy", details: "Cross-reactive with ragweed/daisies.", severity: .high),
            ],
            recipes: [
                Recipe(
                    id: "r5-echinacea-tea",
                    title: "Immune Support Echinacea Tea",
                    type: .tea,
                    difficulty: .beginner,
                    prepTime: "5 minutes",
                    steepOrCureTime: "10 minutes",
                    yield: "1 cup",
                    accessTier: .premium,
                    ingredients: [
                        RecipeIngredient(name: "Dried echinacea root + flower", amount: "1 tbsp", notes: nil),
                        RecipeIngredient(name: "Hot water", amount: "8 oz", notes: nil),
                    ],
                    steps: [
                        RecipeStep(stepNumber: 1, instruction: "Simmer root chips 10 minutes — flowers can be added last 3.", tip: "Take at first sign of a cold, 3x/day, up to 10 days."),
                    ],
                    imageUrl: nil
                ),
            ],
            suggestedPrompts: [
                "When should I start taking echinacea?",
                "Echinacea safety for autoimmune conditions?",
            ],
            lastUpdated: Date(timeIntervalSince1970: 1_744_243_200)
        )
    }

    // MARK: - Collections / Vault / Chat

    static var highlightCollection: HighlightCollection {
        HighlightCollection(
            id: "coll-1",
            title: "Sleep Aids",
            subtitle: "Plants to help you wind down naturally",
            coverImageUrl: "https://cdn.herblens.app/collections/sleep.jpg",
            plantIds: [chamomile.id, lavender.id],
            displayOrder: 0,
            accessTier: .free
        )
    }

    static var highlightCollections: [HighlightCollection] {
        [
            highlightCollection,
            HighlightCollection(
                id: "coll-2",
                title: "Digestive Helpers",
                subtitle: "For everyday comfort after meals",
                coverImageUrl: "https://cdn.herblens.app/collections/digestive.jpg",
                plantIds: [peppermint.id, ginger.id, chamomile.id],
                displayOrder: 1,
                accessTier: .free
            ),
            HighlightCollection(
                id: "coll-3",
                title: "Cold Season Care",
                subtitle: "Warming, supportive herbs for winter",
                coverImageUrl: "https://cdn.herblens.app/collections/cold.jpg",
                plantIds: [ginger.id, echinacea.id],
                displayOrder: 2,
                accessTier: .free
            ),
        ]
    }

    static var conversation: Conversation {
        Conversation(
            id: "conv-1",
            userId: userID,
            startedAt: Date(timeIntervalSince1970: 1_744_243_200),
            lastMessageAt: Date(timeIntervalSince1970: 1_744_243_260),
            contextPlantId: chamomile.id,
            messages: [
                Message(id: "msg-1", role: .user, content: "Is chamomile safe with blood thinners?", timestamp: Date(timeIntervalSince1970: 1_744_243_200)),
                Message(id: "msg-2", role: .assistant, content: "Chamomile contains coumarin which may enhance anticoagulant effects. Consult your doctor.", timestamp: Date(timeIntervalSince1970: 1_744_243_260)),
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

    static var scans: [Scan] {
        [
            scan,
            Scan(
                id: "scan-2",
                userId: userID,
                photoUrl: "https://cdn.herblens.app/scans/demo2.jpg",
                scannedAt: Date(timeIntervalSince1970: 1_744_156_800),
                identifiedPlantId: peppermint.id,
                confidenceScore: 0.88,
                userNotes: "Found by the back garden path.",
                isFavorited: false,
                healthScoreAtScan: 84,
                accessTier: .free
            ),
        ]
    }

    static var offerings: [Offering] {
        [
            Offering(id: "offer-monthly", packageID: "herblens_pro_monthly", displayName: "HerbLens Pro — Monthly", priceString: "$4.99 / mo", tier: .premium, periodDescription: "Renews monthly", trialDays: 7),
            Offering(id: "offer-yearly", packageID: "herblens_pro_yearly", displayName: "HerbLens Pro — Yearly", priceString: "$39.99 / yr", tier: .premium, periodDescription: "Renews yearly", trialDays: 7),
        ]
    }
}
