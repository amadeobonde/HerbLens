import SwiftUI

/// Reusable plant tile used by the featured carousel and collection rows. Shows
/// thumbnail, name, optional alt-name line, and a small score badge.
struct PlantCardView: View {
    let plant: Plant
    var width: CGFloat = 140

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: plant.thumbnailUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        ZStack {
                            Theme.Color.sage.opacity(0.18)
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Theme.Color.sage)
                        }
                    @unknown default:
                        Theme.Color.sage.opacity(0.18)
                    }
                }
                .frame(width: width, height: width)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                ScoreBadge(score: plant.healthScore.overallScore)
                    .padding(Theme.Spacing.xs)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(plant.commonName)
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .lineLimit(1)
                if let tag = plant.tags.first {
                    TagChip(text: tag)
                } else {
                    Text(plant.category)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(width: width, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plant.commonName), \(plant.category), health score \(plant.healthScore.overallScore)")
    }
}

/// Capsule tag chip rendered under the plant name. Uses the subtle glass surface
/// so it reads as a soft companion label rather than competing with the score badge.
private struct TagChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.Font.caption)
            .foregroundStyle(Theme.Color.forest)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, 3)
            .background(Theme.Color.sage.opacity(0.18), in: Capsule())
            .lineLimit(1)
    }
}

private struct ScoreBadge: View {
    let score: Int

    var body: some View {
        Text("\(score)")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.Color.bone)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor, in: Capsule())
    }

    private var badgeColor: SwiftUI.Color {
        switch score {
        case 80...: return Theme.Color.forest
        case 60...79: return Theme.Color.sage
        case 40...59: return Theme.Color.amber
        default: return Theme.Color.ember
        }
    }
}
