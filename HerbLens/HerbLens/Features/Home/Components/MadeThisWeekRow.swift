import SwiftUI

/// "Made this week" — horizontal scroll of recent brews. Pending Instance B3's
/// `BrewsLocalRepository`, this row degrades gracefully to a sleeping-Bamboo empty
/// state. Once the brews source lands, swap the body for the populated horizontal
/// scroll using the same `SectionHeader` shell.
struct MadeThisWeekRow: View {
    /// Closure fired by the empty-state CTA. Marked `@Sendable` because
    /// `EmptyStateView.action` requires it; wired to the Recipes tab once routing exists.
    let onBrowseRecipes: @Sendable () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Made this week")

            EmptyStateView(
                mascot: .sleeping,
                title: "No brews yet",
                subtitle: "Make a recipe and snap a photo.",
                ctaTitle: "Browse recipes",
                action: onBrowseRecipes
            )
            .frame(minHeight: 280)
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}
