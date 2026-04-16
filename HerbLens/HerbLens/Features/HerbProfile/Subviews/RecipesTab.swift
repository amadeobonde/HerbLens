import SwiftUI

/// Lists the plant's recipes. Free-tier users see a dimmed preview behind a Liquid-Glass
/// unlock CTA that routes out to the paywall via `onRequestPaywall`.
struct RecipesTab: View {
    let recipes: [Recipe]
    let isPremium: Bool
    let onRequestPaywall: () -> Void

    var body: some View {
        if recipes.isEmpty {
            EmptyRecipesCard()
        } else {
            ZStack(alignment: .center) {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(recipes) { recipe in
                        RecipePreviewCard(recipe: recipe, locked: !isPremium && recipe.accessTier == .premium)
                    }
                }
                .opacity(isPremium ? 1 : 0.45)
                .allowsHitTesting(isPremium)

                if !isPremium {
                    RecipesPaywallOverlay(onUnlock: onRequestPaywall)
                        .padding(.horizontal, Theme.Spacing.md)
                }
            }
        }
    }
}

private struct RecipePreviewCard: View {
    let recipe: Recipe
    let locked: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: recipe.type == .tea ? "cup.and.saucer.fill" : "drop.fill")
                .font(.title)
                .foregroundStyle(Theme.Color.forest)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.Color.sage.opacity(0.2)))

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(recipe.title)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("\(recipe.prepTime) prep · \(recipe.yield)")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }

            Spacer(minLength: 0)

            if locked {
                Image(systemName: "lock.fill").foregroundStyle(Theme.Color.amber)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(.card)
    }
}

private struct RecipesPaywallOverlay: View {
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(Theme.Color.amber)
            Text("Full recipes are a Premium perk")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
                .multilineTextAlignment(.center)
            Text("Unlock step-by-step teas & tinctures, plus the AI herbalist Bamboo.")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: onUnlock) {
                Text("Unlock with Premium")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.bone)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Capsule().fill(Theme.Color.ember))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Unlock premium recipes")
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .glass(.modal)
    }
}

private struct EmptyRecipesCard: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "cup.and.saucer")
                .font(.title)
                .foregroundStyle(Theme.Color.textSecondary)
            Text("No recipes catalogued for this plant yet.")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textPrimary)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .glass(.card)
    }
}
