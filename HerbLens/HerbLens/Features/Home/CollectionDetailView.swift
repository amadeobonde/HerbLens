import SwiftUI

public struct CollectionDetailView: View {
    let collection: HighlightCollection
    let plants: [Plant]
    
    public init(collection: HighlightCollection, plants: [Plant]) {
        self.collection = collection
        self.plants = plants
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                // Header
                ZStack(alignment: .bottomLeading) {
                    HomeCollectionCoverProvider.image(for: collection)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .overlay(Theme.Color.charcoal.opacity(0.3))
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text(collection.title)
                            .font(Theme.Font.title)
                            .foregroundStyle(Theme.Color.bone)
                        Text(collection.subtitle)
                            .font(Theme.Font.callout)
                            .foregroundStyle(Theme.Color.bone.opacity(0.9))
                    }
                    .padding(Theme.Spacing.lg)
                }
                
                // Plants Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                    ForEach(plants) { plant in
                        NavigationLink(value: HomeRoute.plant(id: plant.id)) {
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                PlantThumbnail(plant: plant)
                                    .frame(height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Text(plant.commonName)
                                    .font(Theme.Font.headline)
                                    .foregroundStyle(Theme.Color.textPrimary)
                                    .lineLimit(1)
                                
                                Text(plant.category)
                                    .font(Theme.Font.caption)
                                    .foregroundStyle(Theme.Color.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
        .background(Theme.Color.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
