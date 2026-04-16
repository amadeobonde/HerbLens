import SwiftUI

/// Full-bleed apothecary hero. The painted scene under `Scenes/Apothecary` carries the
/// emotional pitch; we layer a transparent → background.90 wash so the white headline
/// stays legible on warm or busy regions of the painting.
struct PaywallHeroView: View {
    private let height: CGFloat = 360

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("Scenes/Apothecary")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()

            LinearGradient(
                colors: [
                    Color.clear,
                    Theme.Color.background.opacity(0.9),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: height)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Unlock the apothecary.")
                    .font(Theme.Font.display)
                    .foregroundStyle(.white)
                    .shadow(color: Theme.Color.charcoal.opacity(0.45), radius: 8, x: 0, y: 3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Bamboo's full guidance — scans, recipes, expert chat.")
                    .font(Theme.Font.callout)
                    .foregroundStyle(.white.opacity(0.92))
                    .shadow(color: Theme.Color.charcoal.opacity(0.4), radius: 4, x: 0, y: 1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: height)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Unlock the apothecary — Bamboo's full guidance")
    }
}

#Preview {
    PaywallHeroView()
        .background(Theme.Color.background)
}
