import Foundation
@testable import HerbLens

/// Fixture builders for Vault tests — 9 scans across 7 plant categories (Herb, Root,
/// Flower, Bark, Leaf, Berry, Mushroom) with varying favorites, health scores, and
/// goal breakdowns so every filter + sort path has coverage. Kept inside the test
/// target (not `SampleData.swift`) so expanding fixtures doesn't cross the Instance-2
/// ownership line on `Services/Mock/`.
enum VaultFixtures {
    static let userID = "test-user"

    // MARK: - Plants

    static var chamomile: Plant { plant(id: "p-chamomile", name: "Chamomile", category: "Flower", goals: [("Better Sleep", 90), ("Stress Relief", 85)]) }
    static var lavender: Plant { plant(id: "p-lavender", name: "Lavender", category: "Flower", goals: [("Better Sleep", 92)]) }
    static var peppermint: Plant { plant(id: "p-peppermint", name: "Peppermint", category: "Herb", goals: [("Digestive", 80)]) }
    static var basil: Plant { plant(id: "p-basil", name: "Basil", category: "Herb", goals: [("Immunity", 65)]) }
    static var ginger: Plant { plant(id: "p-ginger", name: "Ginger", category: "Root", goals: [("Digestive", 88)]) }
    static var willowBark: Plant { plant(id: "p-willow", name: "Willow Bark", category: "Bark", goals: [("Pain", 75)]) }
    static var aloe: Plant { plant(id: "p-aloe", name: "Aloe", category: "Leaf", goals: [("Skin", 80)]) }
    static var elderberry: Plant { plant(id: "p-elder", name: "Elderberry", category: "Berry", goals: [("Immunity", 82)]) }
    static var reishi: Plant { plant(id: "p-reishi", name: "Reishi", category: "Mushroom", goals: [("Immunity", 78), ("Stress Relief", 60)]) }

    static var allPlants: [Plant] {
        [chamomile, lavender, peppermint, basil, ginger, willowBark, aloe, elderberry, reishi]
    }

    // MARK: - Scans

    /// 9 scans — two in the Flower and Herb categories (to test category-count tiebreaks),
    /// one in each of the remaining five categories. Favorites and health scores are
    /// deliberately spread so every sort produces a distinct ordering.
    static var scans: [Scan] {
        [
            scan(id: "s1", plant: chamomile, daysAgo: 1, favorited: true,  health: 92),
            scan(id: "s2", plant: lavender,  daysAgo: 4, favorited: false, health: 88),
            scan(id: "s3", plant: peppermint, daysAgo: 2, favorited: false, health: 84),
            scan(id: "s4", plant: basil,     daysAgo: 6, favorited: true,  health: 70),
            scan(id: "s5", plant: ginger,    daysAgo: 3, favorited: false, health: 80),
            scan(id: "s6", plant: willowBark, daysAgo: 7, favorited: false, health: 65),
            scan(id: "s7", plant: aloe,      daysAgo: 8, favorited: true,  health: 90),
            scan(id: "s8", plant: elderberry, daysAgo: 5, favorited: false, health: 72),
            scan(id: "s9", plant: reishi,    daysAgo: 9, favorited: false, health: 60),
        ]
    }

    // MARK: - Builders

    static func plant(id: String,
                      name: String,
                      category: String,
                      goals: [(String, Int)]) -> Plant {
        Plant(
            id: id,
            commonName: name,
            alternateNames: [],
            origin: "Fixture",
            regionsFound: [],
            climates: [],
            growingConditions: nil,
            imageUrl: "https://example.invalid/\(id).jpg",
            thumbnailUrl: "https://example.invalid/\(id)_thumb.jpg",
            description: "\(name) fixture plant.",
            tags: [],
            category: category,
            featured: false,
            accessTier: .free,
            healthScore: HealthScore(
                overallScore: 80,
                goalBreakdown: goals.map {
                    GoalBreakdown(goalName: $0.0, relevanceScore: $0.1, reason: "fixture")
                },
                warnings: []
            ),
            uses: [],
            contraindications: [],
            recipes: [],
            suggestedPrompts: [],
            lastUpdated: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    static func scan(id: String,
                     plant: Plant,
                     daysAgo: Int,
                     favorited: Bool,
                     health: Int) -> Scan {
        let anchor = Date(timeIntervalSince1970: 1_744_243_200)
        let offset = TimeInterval(daysAgo * 24 * 60 * 60)
        return Scan(
            id: id,
            userId: userID,
            photoUrl: "https://example.invalid/scans/\(id).jpg",
            scannedAt: anchor.addingTimeInterval(-offset),
            identifiedPlantId: plant.id,
            confidenceScore: 0.9,
            userNotes: nil,
            isFavorited: favorited,
            healthScoreAtScan: health,
            accessTier: .free
        )
    }
}
