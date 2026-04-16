import SwiftUI

/// Full-screen upsell shown to free users. The CTA calls an injected closure; the real
/// paywall presentation lands with Instance 10, so this view stays a passive promo.
struct ChatPaywallPromo: View {
    var onUpgradeTapped: @Sendable () -> Void = {}

    private let bullets: [String] = [
        "Unlimited conversations with Bamboo",
        "Plant-aware answers that cite your scans",
        "Contraindication tables for every herb",
        "Premium Gemini 3 Pro reasoning"
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            MascotBadge(.teacher, size: 160)
            VStack(spacing: Theme.Spacing.sm) {
                Text("Unlock Bamboo — your herbal mentor")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text("AI Expert Chat is a premium feature.")
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            GlassCard(tone: .standard) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    ForEach(bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                            Image(systemName: "leaf.fill")
                                .foregroundStyle(Theme.Color.sage)
                            Text(bullet)
                                .font(Theme.Font.body)
                                .foregroundStyle(Theme.Color.textPrimary)
                        }
                    }
                }
            }

            PrimaryButton("Upgrade to Premium", action: onUpgradeTapped)
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Color.background.ignoresSafeArea())
    }
}
