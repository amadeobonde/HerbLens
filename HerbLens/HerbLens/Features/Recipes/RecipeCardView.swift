import SwiftUI

/// Tile for a tea recipe. Bundled asset fills the background; falls back
/// to a sage gradient when `RecipeImageLookup` can't resolve the herb.
struct RecipeCardView: View {
    let recipe: Recipe
    let isLocked: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            background
            LinearGradient(
                colors: [Theme.Color.charcoal.opacity(0.0), Theme.Color.charcoal.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.title)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.bone)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(recipe.prepTime)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.bone.opacity(0.85))
            }
            .padding(Theme.Spacing.sm)
            if isLocked {
                lockBadge
                    .padding(Theme.Spacing.xs)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 16))
        .contentShape(.rect(cornerRadius: 16))
    }

    @ViewBuilder private var background: some View {
        if let image = RecipeImageLookup.image(for: recipe) {
            image
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [Theme.Color.sage.opacity(0.8), Theme.Color.forest],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Color.bone.opacity(0.25))
            }
        }
    }

    private var lockBadge: some View {
        Image(systemName: "lock.fill")
            .font(.caption)
            .foregroundStyle(Theme.Color.bone)
            .padding(Theme.Spacing.xxs)
            .background(Theme.Color.amber, in: .circle)
    }
}

#Preview {
    RecipeCardView(
        recipe: RecipePreviewFixtures.teas.first!,
        isLocked: true
    )
    .frame(width: 180)
    .padding()
    .background(Theme.Color.bone)
}
