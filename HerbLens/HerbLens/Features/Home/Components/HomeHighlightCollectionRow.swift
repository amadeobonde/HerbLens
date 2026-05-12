import SwiftUI

/// One row per `HighlightCollection`. A `SectionHeader` shows the collection title
/// with a small accessory bringing in the cover art; below it, a horizontal scroll
/// of plant cards. The cover image comes from the asset catalog when present, else
/// falls back to an SF Symbol via `HomeCollectionCoverProvider`.
///
/// Named with the `Home` prefix to avoid collisions with similarly-named row types
/// other instances may declare.
struct HomeHighlightCollectionRow: View {
    let collection: HighlightCollection
    let plants: [Plant]
    let onSelect: (Plant) -> Void
    let onSelectCollection: (HighlightCollection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Button {
                onSelectCollection(collection)
            } label: {
                HStack {
                    SectionHeader(collection.title) {
                        HomeCollectionCoverProvider.image(for: collection)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous)
                                    .stroke(Theme.Color.sage.opacity(0.25), lineWidth: 0.5)
                            )
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            .buttonStyle(.plain)

            Text(collection.subtitle)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
                .lineLimit(2)
                .padding(.horizontal, Theme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(plants) { plant in
                        Button {
                            onSelect(plant)
                        } label: {
                            GlassCard(tone: .subtle) {
                                PlantCardView(plant: plant, width: 132)
                            }
                            .frame(width: 132 + Theme.Spacing.md * 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
    }
}
