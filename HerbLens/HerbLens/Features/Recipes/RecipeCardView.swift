import SwiftUI

/// Tile for a tea recipe. `HeroPhoto` fills the top half (resolved by
/// `RecipeImageLookup`); a `GlassCard` foot below carries the title,
/// difficulty chip, and prep time. Locked recipes show a lock badge in the
/// upper-right corner of the photo.
struct RecipeCardView: View {
    let recipe: Recipe
    let isLocked: Bool

    private var assetName: String? {
        RecipeImageLookup.assetName(for: recipe).map { "Recipes/\($0)" }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                heroOrPlaceholder
                if isLocked {
                    lockBadge
                        .padding(Theme.Spacing.xs)
                }
            }
            footer
        }
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .glass(.card)
        .shadow(Theme.Shadow.card)
        .contentShape(.rect(cornerRadius: Theme.Radius.md))
    }

    @ViewBuilder
    private var heroOrPlaceholder: some View {
        if let name = assetName {
            HeroPhoto(named: name, height: 140)
        } else {
            ZStack {
                LinearGradient(
                    colors: [Theme.Color.sage.opacity(0.8), Theme.Color.forest],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: Theme.Icon.recipes)
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Color.bone.opacity(0.3))
            }
            .frame(height: 140)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(recipe.title)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            HStack(spacing: Theme.Spacing.xs) {
                difficultyChip
                Label(recipe.prepTime, systemImage: Theme.Icon.timer)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.sm)
    }

    private var difficultyChip: some View {
        Text(recipe.difficulty.rawValue.capitalized)
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(Theme.Color.bone)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, 3)
            .background(Theme.Color.sage, in: .capsule)
    }

    private var lockBadge: some View {
        Image(systemName: "lock.fill")
            .font(.caption)
            .foregroundStyle(Theme.Color.bone)
            .padding(Theme.Spacing.xxs)
            .background(Theme.Color.amber, in: .circle)
            .shadow(Theme.Shadow.float)
    }
}

#Preview {
    HStack(spacing: Theme.Spacing.md) {
        RecipeCardView(
            recipe: RecipePreviewFixtures.teas.first!,
            isLocked: true
        )
        .frame(width: 180)
        RecipeCardView(
            recipe: RecipePreviewFixtures.teas.first!,
            isLocked: false
        )
        .frame(width: 180)
    }
    .padding()
    .background(Theme.Color.background)
}
