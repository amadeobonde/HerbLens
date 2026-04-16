import SwiftUI

/// Unified detail screen for any `VaultItem`. Tapping a card in `VaultHomeView` pushes
/// or presents this view. Both variants share the same chrome — hero photo, title,
/// timestamp, body content, dismiss gesture — but the body section differs by case.
public struct VaultDetailView: View {
    private let item: VaultItem
    private let plant: Plant?
    private let onOpenHerbProfile: (Plant) -> Void
    private let onOpenRecipe: (String) -> Void
    private let onDismiss: () -> Void

    public init(
        item: VaultItem,
        plant: Plant? = nil,
        onOpenHerbProfile: @escaping (Plant) -> Void = { _ in },
        onOpenRecipe: @escaping (String) -> Void = { _ in },
        onDismiss: @escaping () -> Void = {}
    ) {
        self.item = item
        self.plant = plant
        self.onOpenHerbProfile = onOpenHerbProfile
        self.onOpenRecipe = onOpenRecipe
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                hero
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(displayTitle)
                        .font(Theme.Font.display)
                        .foregroundStyle(Theme.Color.textPrimary)

                    Text(item.capturedAt.relativeString)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .padding(.horizontal, Theme.Spacing.md)

                content
                    .padding(.horizontal, Theme.Spacing.md)
            }
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.Color.background.ignoresSafeArea())
        .swipeDownToDismiss { onDismiss() }
    }

    // MARK: - Hero

    @ViewBuilder
    private var hero: some View {
        switch item {
        case .herb(let scan):
            AsyncImage(url: URL(string: scan.photoUrl)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Theme.Color.sage.opacity(0.25)
                }
            }
        case .brew(let brew):
            AsyncImage(url: brew.photoLocalURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Theme.Color.amber.opacity(0.18)
                }
            }
        }
    }

    private var displayTitle: String {
        switch item {
        case .herb: return plant?.commonName ?? "Identified plant"
        case .brew(let brew): return brew.recipeTitle
        }
    }

    // MARK: - Body content

    @ViewBuilder
    private var content: some View {
        switch item {
        case .herb(let scan):
            herbContent(scan: scan)
        case .brew(let brew):
            brewContent(brew: brew)
        }
    }

    @ViewBuilder
    private func herbContent(scan: Scan) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                identificationRow(label: "Confidence",
                                  value: String(format: "%.0f%%", scan.confidenceScore * 100))
                identificationRow(label: "Health score",
                                  value: "\(scan.healthScoreAtScan)")
                if let notes = scan.userNotes, !notes.isEmpty {
                    identificationRow(label: "Notes", value: notes)
                }
            }
        }

        if let plant {
            PrimaryButton("Open herb profile") {
                onOpenHerbProfile(plant)
            }
        }
    }

    @ViewBuilder
    private func brewContent(brew: BrewEntry) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                identificationRow(label: "Brewed",
                                  value: brew.brewedAt.formatted(date: .abbreviated, time: .shortened))
                if let notes = brew.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                        Text(notes)
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.textPrimary)
                    }
                }
            }
        }

        PrimaryButton("Open recipe") {
            onOpenRecipe(brew.recipeID)
        }
    }

    @ViewBuilder
    private func identificationRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
            Spacer(minLength: Theme.Spacing.sm)
            Text(value)
                .font(Theme.Font.callout)
                .foregroundStyle(Theme.Color.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview("Herb") {
    VaultDetailView(
        item: .herb(SampleData.scan),
        plant: SampleData.chamomile
    )
}

#Preview("Brew") {
    VaultDetailView(
        item: .brew(BrewEntry(
            id: "preview-brew",
            recipeID: "recipe-chamomile-tea",
            recipeTitle: "Chamomile Sleep Tea",
            photoLocalURL: URL(fileURLWithPath: "/tmp/preview.jpg"),
            notes: "Steeped 8 minutes — extra honey.",
            brewedAt: Date()
        ))
    )
}
