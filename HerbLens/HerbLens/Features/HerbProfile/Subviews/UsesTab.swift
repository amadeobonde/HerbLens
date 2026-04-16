import SwiftUI

/// Groups `PlantUse` entries by category. Free-tier users see free uses inline; premium
/// ones render with a subtle amber accent to hint at the richer content.
struct UsesTab: View {
    let uses: [PlantUse]
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            if !description.isEmpty {
                Text(description)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(grouped, id: \.category) { group in
                UseGroupCard(category: group.category, entries: group.entries)
            }
        }
    }

    private var grouped: [UseGroup] {
        Dictionary(grouping: uses, by: \.category)
            .map { UseGroup(category: $0.key, entries: $0.value) }
            .sorted { $0.category < $1.category }
    }
}

private struct UseGroup: Hashable {
    let category: String
    let entries: [PlantUse]
}

private struct UseGroupCard: View {
    let category: String
    let entries: [PlantUse]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Label(category, systemImage: "leaf.fill")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            ForEach(entries, id: \.description) { entry in
                HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(Theme.Color.sage)
                        .frame(width: 6, height: 6)
                        .padding(.top, 8)
                    Text(entry.description)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    if entry.accessTier == .premium {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Theme.Color.amber)
                            .accessibilityLabel("Premium content")
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(.card)
    }
}
