import SwiftUI

/// Welcome page — first slide of the onboarding pager. Plays the bundled
/// `BrewHero.mp4` looped inside a `GlassCard(.modal)` and offers the primary
/// "Get started" advance plus a ghost top-right skip.
struct WelcomeView: View {
    let onContinue: @Sendable () -> Void
    var onSkip: (@Sendable () -> Void)? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.Color.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Spacer(minLength: Theme.Spacing.xl)

                GlassCard(tone: .modal) {
                    VideoBackgroundView(
                        resourceName: "BrewHero",
                        resourceExtension: "mp4",
                        fallbackImageName: "Bamboo/Brewing"
                    )
                    .aspectRatio(9.0 / 12.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                }
                .padding(.horizontal, Theme.Spacing.lg)

                VStack(spacing: Theme.Spacing.xs) {
                    Text("Scan. Learn. Brew.")
                        .font(Theme.Font.display)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Identify any herb in seconds, see how it scores against your goals, and brew it right.")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.lg)
                }

                Spacer()

                PrimaryButton("Get started", action: onContinue)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, 72)
            }

            if let onSkip {
                Button(action: onSkip) {
                    Text("Skip")
                        .font(Theme.Font.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Color.forest)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.xs)
                }
                .buttonStyle(.plain)
                .glass(.capsule)
                .clipShape(Capsule())
                .padding(.top, Theme.Spacing.lg)
                .padding(.trailing, Theme.Spacing.lg)
            }
        }
    }
}

#Preview {
    WelcomeView(onContinue: {}, onSkip: {})
}
