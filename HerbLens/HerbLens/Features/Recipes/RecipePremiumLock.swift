import SwiftUI

/// Inline upsell shown in place of locked recipe content. Uses a `GlassCard`
/// at modal tone so the lock visually separates from surrounding ingredient
/// / step cards, and pairs the headline with a `PrimaryButton` (filled, ember)
/// so the trial CTA reads consistently with the rest of the app.
struct RecipePremiumLock: View {
    enum Scope: Hashable {
        case teaSteps
        case fullTincture
    }

    let scope: Scope
    let onTapUpgrade: () -> Void

    var body: some View {
        GlassCard(tone: .modal) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Theme.Color.amber)
                    Text(headline)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                }
                Text(body(for: scope))
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textSecondary)
                PrimaryButton("Start 7-day free trial") {
                    RecipeHaptics.tick()
                    onTapUpgrade()
                }
                .accessibilityLabel("Start 7-day free trial")
            }
        }
        .shadow(Theme.Shadow.modal)
    }

    private var headline: String {
        switch scope {
        case .teaSteps: "Unlock the full brew"
        case .fullTincture: "Premium technique"
        }
    }

    private func body(for scope: Scope) -> String {
        switch scope {
        case .teaSteps:
            "Keep steeping with full steps, tips, and live timer."
        case .fullTincture:
            "Tinctures are a premium HerbLens technique — multi-week cures, ratios, and dosing."
        }
    }
}

#Preview("Tea gate") {
    RecipePremiumLock(scope: .teaSteps, onTapUpgrade: {})
        .padding()
        .background(Theme.Color.bone)
}

#Preview("Tincture gate") {
    RecipePremiumLock(scope: .fullTincture, onTapUpgrade: {})
        .padding()
        .background(Theme.Color.bone)
}
