import SwiftUI

/// Tabs shown under the health-score ring. `rawValue` is used as the accessibility label
/// and segmented-control title. Ordering defines on-screen order.
public nonisolated enum HerbTab: String, CaseIterable, Sendable, Hashable, Identifiable {
    case uses = "Uses"
    case contraindications = "Warnings"
    case recipes = "Recipes"
    case ask = "Ask"

    public var id: String { rawValue }

    public var systemImage: String {
        switch self {
        case .uses: "leaf.fill"
        case .contraindications: "exclamationmark.shield.fill"
        case .recipes: "cup.and.saucer.fill"
        case .ask: "bubble.left.and.text.bubble.right.fill"
        }
    }
}

struct HerbTabSelector: View {
    @Binding var selected: HerbTab

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            ForEach(HerbTab.allCases) { tab in
                TabPill(tab: tab, isSelected: selected == tab) {
                    withAnimation(.spring(duration: 0.3)) { selected = tab }
                }
            }
        }
        .padding(Theme.Spacing.xxs)
        .glass(.capsule)
    }
}

private struct TabPill: View {
    let tab: HerbTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: tab.systemImage)
                .font(Theme.Font.headline)
                .foregroundStyle(isSelected ? Theme.Color.bone : Theme.Color.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(selectionBackground)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
    }

    @ViewBuilder
    private var selectionBackground: some View {
        if isSelected {
            Capsule().fill(Theme.Color.forest)
        } else {
            Color.clear
        }
    }
}
