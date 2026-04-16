import SwiftUI

/// Temporary destination for `HomeRoute.plant(id:)` while Instance 6 (HerbProfile)
/// is still building its real view. When `HerbProfileView` lands, swap the
/// `.navigationDestination` body in `HomeView` to push that instead and delete this file.
struct PendingPlantDetailDestination: View {
    let plantID: String
    @Environment(\.dependencies) private var dependencies
    @State private var plant: Plant?
    @State private var loadError: String?

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Theme.Color.sage)

                if let plant {
                    Text(plant.commonName)
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text(plant.description)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.lg)
                } else if let loadError {
                    Text("Couldn't load plant")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text(loadError)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                } else {
                    ProgressView()
                }

                Text("HerbProfile coming soon")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .padding(.top, Theme.Spacing.md)
            }
            .padding(Theme.Spacing.xl)
        }
        .task(id: plantID) {
            do {
                plant = try await dependencies.plants.plant(id: plantID)
            } catch {
                loadError = error.localizedDescription
            }
        }
    }
}
