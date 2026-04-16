import SwiftUI

/// Per-goal relevance reasons, revealed when the user taps the health-score ring.
struct GoalBreakdownSection: View {
    let breakdown: [GoalBreakdown]
    let isExpanded: Bool

    var body: some View {
        if isExpanded && !breakdown.isEmpty {
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(breakdown, id: \.goalName) { item in
                    GoalBreakdownRow(item: item)
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glass(.card)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.96).combined(with: .opacity),
                removal: .opacity
            ))
        }
    }
}

private struct GoalBreakdownRow: View {
    let item: GoalBreakdown

    private var style: HealthRingStyle { HealthRingStyle(score: item.relevanceScore) }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(item.goalName)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                Spacer()
                Text("\(item.relevanceScore)")
                    .font(Theme.Font.headline.monospacedDigit())
                    .foregroundStyle(style.color)
            }
            progressTrack
            Text(item.reason)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var progressTrack: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Color.forest.opacity(0.12))
                Capsule()
                    .fill(style.color)
                    .frame(width: geo.size.width * style.trimFraction)
            }
        }
        .frame(height: 6)
    }
}
