import SwiftUI

/// Filter / sort chips for the dual-section Vault. Each section presents a slightly
/// different set: Herbs swap "By recipe" out for "By plant" and Brews do the opposite.
/// All chips render as Liquid Glass capsules per the brief.
public struct VaultFilterChips: View {
    public enum Section: Sendable, Hashable {
        case herbs
        case brews
    }

    public enum Chip: String, Sendable, Hashable, CaseIterable {
        case recent
        case favorites
        case byPlant
        case byRecipe

        var title: String {
            switch self {
            case .recent: return "Recent"
            case .favorites: return "Favorites"
            case .byPlant: return "By plant"
            case .byRecipe: return "By recipe"
            }
        }

        var symbol: String {
            switch self {
            case .recent: return "clock"
            case .favorites: return "star.fill"
            case .byPlant: return "leaf"
            case .byRecipe: return "cup.and.saucer"
            }
        }
    }

    private let section: Section
    @Binding private var selection: Chip

    public init(section: Section, selection: Binding<Chip>) {
        self.section = section
        self._selection = selection
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(visibleChips, id: \.self) { chip in
                    chipButton(chip)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var visibleChips: [Chip] {
        switch section {
        case .herbs: return [.recent, .favorites, .byPlant]
        case .brews: return [.recent, .favorites, .byRecipe]
        }
    }

    @ViewBuilder
    private func chipButton(_ chip: Chip) -> some View {
        let isSelected = selection == chip
        Button {
            selection = chip
        } label: {
            HStack(spacing: 6) {
                Image(systemName: chip.symbol)
                    .font(.system(size: 12, weight: .semibold))
                Text(chip.title)
                    .font(Theme.Font.callout)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? Theme.Color.bone : Theme.Color.forest)
            .background(
                Capsule().fill(isSelected ? Theme.Color.forest : Theme.Color.bone)
            )
            .overlay(
                // Subtle sage outline only on unselected chips so they read as
                // distinct from the bone page background. Selected chip is solid
                // forest so no outline needed.
                Capsule()
                    .stroke(Theme.Color.sage.opacity(isSelected ? 0 : 0.45), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Herbs") {
    VStack(spacing: 16) {
        StatefulPreviewWrapper(VaultFilterChips.Chip.recent) { binding in
            VaultFilterChips(section: .herbs, selection: binding)
        }
        StatefulPreviewWrapper(VaultFilterChips.Chip.favorites) { binding in
            VaultFilterChips(section: .brews, selection: binding)
        }
    }
    .padding()
    .background(Theme.Color.background)
}

/// Tiny helper so previews can demo a `@Binding`-driven chip without dragging in a
/// full view model. Local to the file because it's preview-only.
private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(_ initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initial)
        self.content = content
    }

    var body: some View { content($value) }
}
