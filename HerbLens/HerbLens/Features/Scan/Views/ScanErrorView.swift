import SwiftUI

/// Error view for the Scan flow. Uses the confused mascot to signal something went
/// wrong, and routes the user back via the same dismiss closure regardless of
/// retriability.
struct ScanErrorView: View {
    let error: ScanDisplayError
    let onDismiss: @Sendable () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Color.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    MascotBadge(.confused, size: 160)
                        .padding(.top, Theme.Spacing.xl)

                    GlassCard {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: Theme.Icon.error)
                                    .foregroundStyle(Theme.Color.ember)
                                Text(error.title)
                                    .font(Theme.Font.headline)
                                    .foregroundStyle(Theme.Color.textPrimary)
                            }
                            Text(error.message)
                                .font(Theme.Font.body)
                                .foregroundStyle(Theme.Color.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                            .stroke(Theme.Color.ember.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.horizontal, Theme.Spacing.md)

                    Color.clear.frame(height: 120)
                }
            }

            stickyAction
        }
    }

    private var stickyAction: some View {
        PrimaryButton(error.retriable ? "Try again" : "OK", action: onDismiss)
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
