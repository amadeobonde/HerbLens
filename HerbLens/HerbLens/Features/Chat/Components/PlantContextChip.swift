import SwiftUI

/// Shows the context plant for a thread — displayed above the input bar so the user
/// always knows which plant Bamboo is answering about. Tapping is a no-op in v1; future
/// refinement could let users detach the context mid-thread.
struct PlantContextChip: View {
    let plant: Plant

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            AsyncImage(url: URL(string: plant.thumbnailUrl)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Theme.Color.sage.opacity(0.25)
                }
            }
            .frame(width: 24, height: 24)
            .clipShape(Circle())

            Text("About \(plant.commonName)")
                .font(Theme.Font.caption.weight(.medium))
                .foregroundStyle(Theme.Color.forest)

            Image(systemName: "leaf.fill")
                .font(.caption2)
                .foregroundStyle(Theme.Color.sage)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .glass(.capsule)
    }
}
