import SwiftUI

/// Inline upsell shown in place of locked recipe content. Keeps the visual
/// weight consistent whether gating a single step (tea) or an entire detail
/// view (tincture).
struct RecipePremiumLock: View {
    enum Scope: Hashable {
        case teaSteps
        case fullTincture
    }

    let scope: Scope
    let onTapUpgrade: () -> Void

    var body: some View {
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
            Button(action: onTapUpgrade) {
                Text("Start 7-day free trial")
                    .font(Theme.Font.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Color.bone)
                    .padding(.vertical, Theme.Spacing.sm)
                    .padding(.horizontal, Theme.Spacing.md)
                    .background(Theme.Color.ember, in: .capsule)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start 7-day free trial")
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(.modal)
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
