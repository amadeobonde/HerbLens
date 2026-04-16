import SwiftUI

/// Tile for a tincture recipe. Forest-green hero with the amber ribbon — visually
/// distinct from tea cards to signal "more concentrated preparation". Wraps in a
/// `GlassCard` so elevation + corner radius match the rest of the grid.
struct TinctureCardView: View {
    let recipe: Recipe

    private var assetName: String? {
        RecipeImageLookup.assetName(for: recipe).map { "Recipes/\($0)" }
    }

    var body: some View {
        VStack(spacing: 0) {
            hero
            footer
        }
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .glass(.card)
        .shadow(Theme.Shadow.card)
        .contentShape(.rect(cornerRadius: Theme.Radius.md))
    }

    @ViewBuilder
    private var hero: some View {
        ZStack {
            Theme.Color.forest
            if let name = assetName {
                HeroPhoto(named: name, height: 140)
            } else {
                Image(systemName: "drop.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.Color.amber)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .clipped()
    }

    private var footer: some View {
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
            Label("Cure: \(recipe.steepOrCureTime ?? "—") · \(recipe.difficulty.rawValue.capitalized)",
                  systemImage: Theme.Icon.timer)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.bone.opacity(0.75))
                .lineLimit(1)
        }
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.forest)
    }
}

#Preview {
    TinctureCardView(recipe: RecipePreviewFixtures.localTinctures[0])
        .frame(width: 180)
        .padding()
        .background(Theme.Color.bone)
}
