import SwiftUI

/// Paywall CTA shown when a free-tier user has hit the daily scan cap.
struct QuotaReachedView: View {
    let limit: Int
    let onPaywall: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Theme.Color.forest)
                    .padding(Theme.Spacing.xl)
                    .background(Circle().fill(Theme.Color.bone.opacity(0.8)))

                VStack(spacing: Theme.Spacing.xs) {
                    Text("That's your \(limit) for today")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Premium unlocks unlimited scans, AI chat with Bamboo, and full recipes.")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.lg)
                }

                Button(action: onPaywall) {
                    Text("Go Premium")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Color.bone)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Capsule().fill(Theme.Color.forest))
                }
                .padding(.horizontal, Theme.Spacing.lg)

                Button("Come back tomorrow", action: onDismiss)
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .padding(Theme.Spacing.xl)
        }
    }
}
