import SwiftUI

/// Tile for a tincture recipe. Forest-green base with amber ribbon — visually
/// distinct from tea cards to signal "more concentrated preparation" per the
/// brand brief.
struct TinctureCardView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Theme.Color.forest
                if let image = RecipeImageLookup.image(for: recipe) {
                    image
                        .resizable()
                        .scaledToFit()
                        .padding(Theme.Spacing.md)
                } else {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.Color.amber)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                HStack(spacing: Theme.Spacing.xxs) {
                    Text("TINCTURE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.Color.bone)
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.vertical, 3)
                        .background(Theme.Color.amber, in: .capsule)
                    Spacer(minLength: 0)
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.amber)
                }
                Text(recipe.title)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.bone)
                    .lineLimit(2)
                Text("Cure: \(recipe.steepOrCureTime ?? "—") · \(recipe.difficulty.rawValue.capitalized)")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.bone.opacity(0.7))
            }
            .padding(Theme.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Color.forest)
        }
        .clipShape(.rect(cornerRadius: 16))
        .contentShape(.rect(cornerRadius: 16))
    }
}

#Preview {
    TinctureCardView(recipe: RecipePreviewFixtures.localTinctures[0])
        .frame(width: 180)
        .padding()
        .background(Theme.Color.bone)
}
