import SwiftUI

/// Temporary root view that confirms Shared Foundation is wired. Instance 4 (Home) will
/// replace this with the actual home screen once their branch merges.
struct ContentView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var tier: SubscriptionTier = .free

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Theme.Color.sage)

                VStack(spacing: Theme.Spacing.xs) {
                    Text("HerbLens")
                        .font(Theme.Font.display)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("Scan. Learn. Brew.")
                        .font(Theme.Font.callout)
                        .foregroundStyle(Theme.Color.textSecondary)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Shared Foundation")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("Current tier: \(tier.rawValue)")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .padding(Theme.Spacing.md)
                .glass(.card)
            }
            .padding(Theme.Spacing.xl)
        }
        .task {
            tier = await dependencies.subscriptions.currentTier()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.dependencies, .mock)
}
