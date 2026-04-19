import SwiftUI

/// Generic empty-state placeholder: mascot, headline, optional subtitle, optional CTA.
/// Drop into list views and tab roots when there's nothing to show yet.
public struct EmptyStateView: View {
    private nonisolated let mascot: MascotBadge.Variant
    private nonisolated let title: String
    private nonisolated let subtitle: String?
    private nonisolated let ctaTitle: String?
    private nonisolated let action: (@Sendable () -> Void)?

    public nonisolated init(
        mascot: MascotBadge.Variant = .sleeping,
        title: String,
        subtitle: String? = nil,
        ctaTitle: String? = nil,
        action: (@Sendable () -> Void)? = nil
    ) {
        self.mascot = mascot
        self.title = title
        self.subtitle = subtitle
        self.ctaTitle = ctaTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            MascotBadge(mascot, size: 140, behavior: mascot == .sleeping ? .sleepy : .idle)

            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.lg)
                }
            }

            if let ctaTitle, let action {
                PrimaryButton(ctaTitle, action: action)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.top, Theme.Spacing.xs)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        mascot: .sleeping,
        title: "No scans yet",
        subtitle: "Point your camera at any plant to get started.",
        ctaTitle: "Open scanner",
        action: {}
    )
    .background(Theme.Color.background)
}
