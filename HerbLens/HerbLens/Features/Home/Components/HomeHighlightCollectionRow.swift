import SwiftUI

/// One row per `HighlightCollection`: cover art on the left, title + subtitle, and
/// a horizontal scroll of plant cards. The cover image comes from the asset catalog
/// when present, else falls back to an SF Symbol via `HomeCollectionCoverProvider`.
///
/// Named with the `Home` prefix to avoid collisions with similarly-named row types
/// other instances may declare.
struct HomeHighlightCollectionRow: View {
    let collection: HighlightCollection
    let plants: [Plant]
    let onSelect: (Plant) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header
                .padding(.horizontal, Theme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(plants) { plant in
                        Button {
                            onSelect(plant)
                        } label: {
                            PlantCardView(plant: plant, width: 132)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.md) {
            HomeCollectionCoverProvider.image(for: collection)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Theme.Color.sage.opacity(0.25), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(collection.title)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .lineLimit(1)
                Text(collection.subtitle)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
    }
}
