import SwiftUI

/// Premium-only section. Renders any collections marked `accessTier == .premium`
/// in the loaded data — filtering by tier rather than maintaining a separate
/// hardcoded list keeps a single source of truth.
struct CuratedForYouSection: View {
    let collections: [HighlightCollection]
    let plantsByID: [String: Plant]
    let onSelect: (Plant) -> Void

    var body: some View {
        if !collections.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.Color.amber)
                    Text("Curated for you")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Spacer(minLength: 0)
                    Text("Premium")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.bone)
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.vertical, 3)
                        .background(Theme.Color.forest, in: Capsule())
                }
                .padding(.horizontal, Theme.Spacing.md)

                ForEach(collections) { collection in
                    HomeHighlightCollectionRow(
                        collection: collection,
                        plants: plants(for: collection),
                        onSelect: onSelect
                    )
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.Color.sage.opacity(0.08))
                    .padding(.horizontal, Theme.Spacing.xs)
            )
        }
    }

    private func plants(for collection: HighlightCollection) -> [Plant] {
        collection.plantIds.compactMap { plantsByID[$0] }
    }
}
