import SwiftUI

/// Horizontal carousel of featured plants. Wraps `PlantCardView` with a section
/// header and emits the selected plant through a callback so `HomeView` controls
/// the `NavigationStack` path.
struct FeaturedPlantsCarousel: View {
    let plants: [Plant]
    let onSelect: (Plant) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Featured plants")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
                .padding(.horizontal, Theme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(plants) { plant in
                        Button {
                            onSelect(plant)
                        } label: {
                            PlantCardView(plant: plant, width: 156)
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
