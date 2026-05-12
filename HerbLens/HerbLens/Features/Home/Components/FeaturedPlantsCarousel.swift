import SwiftUI

/// Horizontal carousel of featured plants. Wraps each `PlantCardView` in a
/// `GlassCard` with a leading tags chip so the card chrome stays consistent with
/// the rest of the home feed. Selection bubbles up via `onSelect` so `HomeView`
/// owns the `NavigationStack` path.
struct FeaturedPlantsCarousel: View {
    let plants: [Plant]
    let onSelect: (Plant) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader("Featured this week")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(plants) { plant in
                        Button {
                            onSelect(plant)
                        } label: {
                            GlassCard(tone: .standard) {
                                PlantCardView(plant: plant, width: 156)
                            }
                            .frame(width: 156 + Theme.Spacing.md * 2)
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
