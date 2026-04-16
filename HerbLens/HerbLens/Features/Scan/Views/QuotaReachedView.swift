import SwiftUI

/// Paywall CTA shown when a free-tier user has hit the daily scan cap. Sleeping
/// Bamboo + offering tease card with the Apothecary scene + a `PrimaryButton` that
/// hands off to the dedicated paywall flow.
struct QuotaReachedView: View {
    let limit: Int
    let onPaywall: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Color.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    MascotBadge(.sleeping, size: 160)
                        .padding(.top, Theme.Spacing.xl)

                    VStack(spacing: Theme.Spacing.xs) {
                        Text("That's your \(limit) for today")
                            .font(Theme.Font.title)
                            .foregroundStyle(Theme.Color.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Bamboo is napping. Premium keeps the scanner open all day.")
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.lg)
                    }

                    teaseCard
                        .padding(.horizontal, Theme.Spacing.md)

                    Color.clear.frame(height: 140)
                }
            }

            stickyActions
        }
    }

    private var teaseCard: some View {
        GlassCard(tone: .modal) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HeroPhoto(named: "Scenes/Apothecary", height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))

                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text("Premium unlocks")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("Unlimited scans, AI chat with Bamboo, and the full apothecary of brews and tinctures.")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: Theme.Spacing.xs) {
                    perkRow(icon: Theme.Icon.scan, text: "Unlimited daily scans")
                    perkRow(icon: Theme.Icon.chat, text: "AI chat with Bamboo")
                    perkRow(icon: Theme.Icon.recipes, text: "Full recipe & tincture library")
                }
            }
        }
    }

    private func perkRow(icon: String, text: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Theme.Color.sage)
                .frame(width: 22)
            Text(text)
                .font(Theme.Font.callout)
                .foregroundStyle(Theme.Color.textPrimary)
            Spacer()
        }
    }

    private var stickyActions: some View {
        VStack(spacing: Theme.Spacing.xs) {
            PrimaryButton("Unlock unlimited", action: onPaywall)
            PrimaryButton("Come back tomorrow", variant: .ghost, action: onDismiss)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            Color.clear
                .glass(.subtle)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        )
        .shadow(Theme.Shadow.float)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.lg)
    }
}
