import SwiftUI

/// Pure presentation rules for the Liquid Glass health-score ring. Split out from the
/// view so the score → (trimFraction, color, label) mapping is testable without
/// instantiating SwiftUI.
public nonisolated struct HealthRingStyle: Sendable, Hashable {
    public let score: Int
    public let trimFraction: Double
    public let color: SwiftUI.Color
    public let label: String

    public init(score rawScore: Int) {
        let clamped = max(0, min(100, rawScore))
        self.score = clamped
        self.trimFraction = Double(clamped) / 100.0

        switch clamped {
        case ..<40:
            self.color = Theme.Color.ember
            self.label = "low match"
        case 40..<70:
            self.color = Theme.Color.amber
            self.label = "moderate match"
        default:
            self.color = Theme.Color.sage
            self.label = "strong match"
        }
    }
}
