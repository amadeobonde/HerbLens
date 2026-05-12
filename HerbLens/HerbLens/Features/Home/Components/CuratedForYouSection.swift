import SwiftUI

/// Premium-only section. Renders any collections marked `accessTier == .premium`
/// in the loaded data — filtering by tier rather than maintaining a separate
/// hardcoded list keeps a single source of truth.
struct CuratedForYouSection: View {
    let collections: [HighlightCollection]
    let plantsByID: [String: Plant]
    let onSelect: (Plant) -> Void
    let onSelectCollection: (HighlightCollection) -> Void

    var body: some View {
        if !collections.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionHeader("Curated for you") {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: Theme.Icon.paywall)
                            .font(.system(size: 14, weight: .semibold))
                        Text("Premium")
                            .font(Theme.Font.caption)
                    }
                    .foregroundStyle(Theme.Color.bone)
                    .padding(.horizontal, Theme.Spacing.xs)
                    .padding(.vertical, 4)
                    .background(Theme.Color.forest, in: Capsule())
                }

                ForEach(collections) { collection in
                    HomeHighlightCollectionRow(
                        collection: collection,
                        plants: plants(for: collection),
                        onSelect: onSelect,
                        onSelectCollection: onSelectCollection
                    )
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .fill(Theme.Color.sage.opacity(0.08))
                    .padding(.horizontal, Theme.Spacing.xs)
            )
        }
    }

    private func plants(for collection: HighlightCollection) -> [Plant] {
        collection.plantIds.compactMap { plantsByID[$0] }
    }
}
