import SwiftUI

/// Full-screen upsell shown to free users. The CTA calls an injected closure; the real
/// paywall presentation lands with Instance 10, so this view stays a passive promo.
struct ChatPaywallPromo: View {
    var onUpgradeTapped: () -> Void = {}

    private let bullets: [String] = [
        "Unlimited conversations with Bamboo",
        "Plant-aware answers that cite your scans",
        "Contraindication tables for every herb",
        "Premium Gemini 3 Pro reasoning"
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            BambooAvatarView(size: 160)
            VStack(spacing: Theme.Spacing.sm) {
                Text("Unlock Bamboo — your herbal mentor")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.charcoal)
                    .multilineTextAlignment(.center)
                Text("AI Expert Chat is a premium feature.")
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(Theme.Color.sage)
                        Text(bullet)
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.charcoal)
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glass(.card)

            Button(action: onUpgradeTapped) {
                Text("Upgrade to Premium")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.bone)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Theme.Color.forest, in: Capsule())
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Color.background.ignoresSafeArea())
    }
}
