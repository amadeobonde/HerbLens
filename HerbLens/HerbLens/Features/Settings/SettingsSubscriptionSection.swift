import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Subscription row: shows current tier + actions to upgrade / manage / restore.
/// Presents the paywall via a sheet for free users and deep-links to the Apple ID
/// Subscriptions screen for premium users.
struct SettingsSubscriptionSection: View {
    let tier: SubscriptionTier
    let summary: String
    let isRestoring: Bool
    let onUpgrade: @Sendable () -> Void
    let onRestore: @Sendable () -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Subscription")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)

                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: tier == .premium ? Theme.Icon.paywall : Theme.Icon.recipes)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(tier == .premium ? Theme.Color.amber : Theme.Color.sage)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tier == .premium ? "HerbLens Pro" : "HerbLens Free")
                            .font(Theme.Font.callout.weight(.semibold))
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text(summary)
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    Spacer(minLength: 0)
                }

                primaryAction
                restoreButton
            }
        }
    }

    @ViewBuilder
    private var primaryAction: some View {
        switch tier {
        case .free:
            PrimaryButton("Upgrade to Pro", variant: .filled, action: onUpgrade)
        case .premium:
            PrimaryButton("Manage subscription", variant: .ghost) {
                Task { @MainActor in Self.openAppStoreSubscriptions() }
            }
        }
    }

    private var restoreButton: some View {
        Button(action: onRestore) {
            HStack(spacing: Theme.Spacing.xs) {
                if isRestoring {
                    ProgressView().controlSize(.small)
                }
                Text("Restore purchases")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, Theme.Spacing.xxs)
        }
        .buttonStyle(.plain)
        .disabled(isRestoring)
    }

    private static func openAppStoreSubscriptions() {
        #if canImport(UIKit)
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
        #endif
    }
}
