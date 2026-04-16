import SwiftUI

/// Dual-section Vault entry point. A segmented "Herbs / Brews" picker switches between
/// two 2-column grids of `VaultItem` thumbnails. Each card shows a photo, the item
/// title, and a relative-date caption. Empty states use the bamboo-sleeping mascot
/// with a section-appropriate CTA.
///
/// This view is deliberately UI-only — it accepts pre-resolved arrays of items rather
/// than calling repositories directly so it composes cleanly under the existing
/// `VaultViewModel` (scans side) and any forthcoming brews loader. Wiring lives in
/// `VaultView` (the older single-section root) until root navigation merges and can
/// pick the dual-section flow.
public struct VaultHomeView: View {
    public enum Section: String, Sendable, Hashable, CaseIterable {
        case herbs
        case brews

        var title: String {
            switch self {
            case .herbs: return "Herbs"
            case .brews: return "Brews"
            }
        }
    }

    private let herbs: [VaultItem]
    private let brews: [VaultItem]
    private let plantsByID: [String: Plant]
    private let onSelect: (VaultItem) -> Void
    private let onScanCTA: () -> Void
    private let onBrewCTA: () -> Void

    @State private var section: Section = .herbs
    @State private var herbsChip: VaultFilterChips.Chip = .recent
    @State private var brewsChip: VaultFilterChips.Chip = .recent

    public init(
        herbs: [VaultItem],
        brews: [VaultItem],
        plantsByID: [String: Plant] = [:],
        onSelect: @escaping (VaultItem) -> Void = { _ in },
        onScanCTA: @escaping () -> Void = {},
        onBrewCTA: @escaping () -> Void = {}
    ) {
        self.herbs = herbs
        self.brews = brews
        self.plantsByID = plantsByID
        self.onSelect = onSelect
        self.onScanCTA = onScanCTA
        self.onBrewCTA = onBrewCTA
    }

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: Theme.Spacing.md),
        GridItem(.flexible(), spacing: Theme.Spacing.md),
    ]

    public var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            vaultHeader
                .padding(.horizontal, Theme.Spacing.md)

            picker
                .padding(.horizontal, Theme.Spacing.md)

            VaultFilterChips(section: filterSection, selection: chipBinding)

            content
        }
        .padding(.top, Theme.Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Color.background.ignoresSafeArea())
    }

    /// Mascot-led section header. Teacher Bamboo for Herbs (educational framing),
    /// brewing Bamboo for Brews (kitchen framing). Picks up the variant when the
    /// segmented picker flips so the mood matches the active tab.
    private var vaultHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            MascotBadge(section == .herbs ? .teacher : .brewing, size: 72)

            VStack(alignment: .leading, spacing: 2) {
                Text(section == .herbs ? "Your herb library" : "Your brews")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text(section == .herbs
                     ? "Every plant you've scanned."
                     : "Every brew you've made.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Picker

    private var picker: some View {
        Picker("Vault section", selection: $section) {
            ForEach(Section.allCases, id: \.self) { section in
                Text(section.title).tag(section)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Filter chips wiring

    private var filterSection: VaultFilterChips.Section {
        section == .herbs ? .herbs : .brews
    }

    private var chipBinding: Binding<VaultFilterChips.Chip> {
        section == .herbs ? $herbsChip : $brewsChip
    }

    // MARK: - Section content

    @ViewBuilder
    private var content: some View {
        switch section {
        case .herbs:
            grid(for: applyChip(to: herbs, chip: herbsChip), emptyState: emptyHerbs)
        case .brews:
            grid(for: applyChip(to: brews, chip: brewsChip), emptyState: emptyBrews)
        }
    }

    @ViewBuilder
    private func grid(for items: [VaultItem], emptyState: EmptyStateView) -> some View {
        if items.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: Theme.Spacing.md) {
                    ForEach(items) { item in
                        Button { onSelect(item) } label: {
                            VaultItemCard(item: item, plant: plantOf(item))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
            }
        }
    }

    private func plantOf(_ item: VaultItem) -> Plant? {
        if case .herb(let scan) = item { return plantsByID[scan.identifiedPlantId] }
        return nil
    }

    // MARK: - Sort/filter chip application

    private func applyChip(to items: [VaultItem], chip: VaultFilterChips.Chip) -> [VaultItem] {
        switch chip {
        case .recent:
            return items.sorted { $0.capturedAt > $1.capturedAt }
        case .favorites:
            return items.filter(\.isFavorited).sorted { $0.capturedAt > $1.capturedAt }
        case .byPlant:
            return items.sorted { lhs, rhs in
                let l = plantOf(lhs)?.commonName ?? ""
                let r = plantOf(rhs)?.commonName ?? ""
                return l.localizedCaseInsensitiveCompare(r) == .orderedAscending
            }
        case .byRecipe:
            return items.sorted { lhs, rhs in
                let l = recipeTitle(of: lhs)
                let r = recipeTitle(of: rhs)
                return l.localizedCaseInsensitiveCompare(r) == .orderedAscending
            }
        }
    }

    private func recipeTitle(of item: VaultItem) -> String {
        if case .brew(let brew) = item { return brew.recipeTitle }
        return ""
    }

    // MARK: - Empty states

    private var emptyHerbs: EmptyStateView {
        EmptyStateView(
            mascot: .sleeping,
            title: "Empty for now",
            subtitle: "Scan a plant to start your herb collection.",
            ctaTitle: "Scan a plant",
            action: { onScanCTA() }
        )
    }

    private var emptyBrews: EmptyStateView {
        EmptyStateView(
            mascot: .sleeping,
            title: "Empty for now",
            subtitle: "Brew a recipe to capture it in your vault.",
            ctaTitle: "Brew a recipe",
            action: { onBrewCTA() }
        )
    }
}

/// Single tile rendered inside the dual-section grid. Smaller and more generic than
/// the pre-existing `VaultCard` (which is scan-specific) so it can render either
/// vault-item case from the same code path.
private struct VaultItemCard: View {
    let item: VaultItem
    let plant: Plant?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            thumbnail
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    if item.isFavorited {
                        Image(systemName: "star.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.Color.amber)
                            .padding(6)
                            .background(.ultraThinMaterial, in: Circle())
                            .padding(6)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(displayTitle)
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .lineLimit(1)
                Text(item.capturedAt.shortRelativeString)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .padding(.horizontal, Theme.Spacing.xxs)
        }
    }

    private var displayTitle: String {
        switch item {
        case .herb: return plant?.commonName ?? "Identified plant"
        case .brew(let brew): return brew.recipeTitle
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = item.thumbnailURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    placeholder
                case .empty:
                    placeholder.redacted(reason: .placeholder)
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        ZStack {
            Theme.Color.sage.opacity(0.12)
            Image(systemName: iconForCase)
                .font(.system(size: 28))
                .foregroundStyle(Theme.Color.sage.opacity(0.6))
        }
    }

    private var iconForCase: String {
        switch item {
        case .herb: return "leaf.fill"
        case .brew: return "cup.and.saucer.fill"
        }
    }
}

#Preview("Populated") {
    VaultHomeView(
        herbs: [.herb(SampleData.scan)],
        brews: [
            .brew(BrewEntry(
                recipeID: "tea-chamomile",
                recipeTitle: "Chamomile Sleep Tea",
                photoLocalURL: URL(fileURLWithPath: "/tmp/p.jpg"),
                notes: "Lovely",
                brewedAt: Date(),
                isFavorited: true
            ))
        ],
        plantsByID: ["plant-chamomile": SampleData.chamomile]
    )
}

#Preview("Empty") {
    VaultHomeView(herbs: [], brews: [])
}
