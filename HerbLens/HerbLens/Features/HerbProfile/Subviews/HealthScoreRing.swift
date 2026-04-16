import SwiftUI

/// Liquid-Glass health-score ring. Applies `.glassEffect(.regular.interactive(), in: .circle)`
/// directly — the shared Theme `.glass(_:)` helper has no circle role yet and adding one
/// for a single use would be noise outside Instance 1's ownership.
struct HealthScoreRing: View {
    let score: Int
    let isPremium: Bool
    let isExpanded: Bool
    let onToggle: () -> Void

    @State private var animatedFraction: Double = 0

    private var style: HealthRingStyle { HealthRingStyle(score: score) }

    var body: some View {
        Button(action: onToggle) {
            ZStack {
                track
                progressArc
                centerLabel
            }
            .frame(width: 200, height: 200)
            .glassEffect(.regular.interactive(), in: .circle)
            .premiumShimmer(enabled: isPremium)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Health match score \(style.score) out of 100, \(style.label)")
            .accessibilityHint(isExpanded ? "Hide goal breakdown" : "Show per-goal breakdown")
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedFraction = style.trimFraction
            }
        }
        .onChange(of: style.trimFraction) { _, newValue in
            withAnimation(.easeOut(duration: 0.8)) { animatedFraction = newValue }
        }
    }

    private var track: some View {
        Circle()
            .stroke(Theme.Color.forest.opacity(0.12), lineWidth: 14)
    }

    private var progressArc: some View {
        Circle()
            .trim(from: 0, to: animatedFraction)
            .stroke(style.color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
            .rotationEffect(.degrees(-90))
    }

    private var centerLabel: some View {
        VStack(spacing: Theme.Spacing.xxs) {
            Text("\(style.score)")
                .font(Theme.Font.display)
                .foregroundStyle(Theme.Color.textPrimary)
                .contentTransition(.numericText())
            Text(style.label.uppercased())
                .font(Theme.Font.caption.weight(.semibold))
                .foregroundStyle(style.color)
                .tracking(1.1)
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption2)
                .foregroundStyle(Theme.Color.textSecondary)
                .padding(.top, 2)
        }
    }
}
