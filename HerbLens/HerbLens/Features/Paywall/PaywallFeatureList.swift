import SwiftUI

/// Hard-coded "Premium glow" feature list shown on the paywall. Ordering intentional:
/// headline conversion drivers first (AI chat + detailed insights), then content depth,
/// then polish. Copy is stable — free-tier footnotes highlight what the user is missing.
nonisolated struct PaywallFeature: Identifiable, Hashable, Sendable {
    let id: String
    let icon: String
    let title: String
    let freeFootnote: String

    static let all: [PaywallFeature] = [
        PaywallFeature(
            id: "detailed-health",
            icon: "chart.bar.fill",
            title: "Detailed health score breakdowns",
            freeFootnote: "Free tier: overall score only"
        ),
        PaywallFeature(
            id: "ai-chat",
            icon: "message.badge.waveform",
            title: "AI Expert Chat with Bamboo",
            freeFootnote: "Free tier: no access"
        ),
        PaywallFeature(
            id: "full-recipes",
            icon: "cup.and.saucer.fill",
            title: "Full recipes and tinctures",
            freeFootnote: "Free tier: preview only"
        ),
        PaywallFeature(
            id: "deeper-insights",
            icon: "sparkles",
            title: "Personalized warnings and contraindication detail",
            freeFootnote: "Free tier: basic warnings"
        ),
        PaywallFeature(
            id: "animations-haptics",
            icon: "wand.and.rays",
            title: "Premium animations and haptics",
            freeFootnote: ""
        ),
        PaywallFeature(
            id: "priority-id",
            icon: "bolt.fill",
            title: "Priority plant identification",
            freeFootnote: ""
        ),
    ]
}

/// Single "Includes" row: sage circle + check mark, optional context icon, title, and
/// optional free-tier footnote. Stacks neatly inside `PaywallFeatureList`.
struct PaywallFeatureRow: View {
    let feature: PaywallFeature

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.Color.sage.opacity(0.18))
                    .frame(width: 28, height: 28)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.Color.sage)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: Theme.Spacing.xs) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Color.amber)
                        .frame(width: 20)
                        .accessibilityHidden(true)
                    Text(feature.title)
                        .font(Theme.Font.callout)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !feature.freeFootnote.isEmpty {
                    Text(feature.freeFootnote)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary.opacity(0.85))
                        .padding(.leading, 28)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Theme.Spacing.xxs)
    }
}

/// Premium glow feature list. Wrapped in a `GlassCard(tone: .subtle)` so it grounds the
/// paywall while letting the offering cards above carry the visual weight.
struct PaywallFeatureList: View {
    var body: some View {
        GlassCard(tone: .subtle) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Includes")
                    .font(Theme.Font.caption.weight(.semibold))
                    .foregroundStyle(Theme.Color.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .padding(.bottom, Theme.Spacing.xxs)

                ForEach(PaywallFeature.all) { feature in
                    PaywallFeatureRow(feature: feature)
                }
            }
        }
    }
}
