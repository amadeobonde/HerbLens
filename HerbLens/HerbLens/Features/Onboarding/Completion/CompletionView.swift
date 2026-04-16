import SwiftUI

struct CompletionView: View {
    let tier: SubscriptionTier
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(heroAsset)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
                .padding(.horizontal, Theme.Spacing.lg)

            VStack(spacing: Theme.Spacing.sm) {
                Text(headline)
                    .font(Theme.Font.display)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }

            if tier == .premium {
                PremiumBadge()
                    .padding(.top, Theme.Spacing.xs)
            }

            Spacer()

            OnboardingPrimaryButton(title: "Start scanning", action: onContinue)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.lg)
        }
        .background(Theme.Color.background.ignoresSafeArea())
    }

    private var heroAsset: String {
        tier == .premium ? "bamboo-celebrating" : "bamboo-brewing"
    }

    private var headline: String {
        tier == .premium ? "Welcome to HerbLens Pro" : "You're all set"
    }

    private var subtitle: String {
        tier == .premium
            ? "Unlimited scans, Bamboo's expert chat, full recipes, and deeper health insights are unlocked."
            : "Point your camera at a herb and we'll take it from there."
    }
}

private struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "sparkles")
            Text("Pro")
                .font(Theme.Font.callout)
                .fontWeight(.semibold)
        }
        .foregroundStyle(Theme.Color.amber)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Capsule().fill(Theme.Color.amber.opacity(0.15)))
    }
}

#Preview("Free") {
    CompletionView(tier: .free, onContinue: {})
}

#Preview("Premium") {
    CompletionView(tier: .premium, onContinue: {})
}
