import SwiftUI

/// Page 2 of the pager. Mascot-led goal selector — multi-select chips for the
/// most common health goals, written in the human-friendly tone the spec asks
/// for ("Better sleep" rather than the older "Sleep" preset).
struct GoalsPickerPage: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    /// Spec-mandated chips. Mapped onto draft goals 1:1 by display name —
    /// `OnboardingViewModel.addGoal(named:)` already deduplicates on
    /// case-insensitive name compare.
    private static let presets: [String] = [
        "Better sleep",
        "Stress relief",
        "Digestion",
        "Immunity",
        "Energy",
        "Skin",
        "Joint comfort"
    ]

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    VStack(spacing: Theme.Spacing.sm) {
                        MascotBadge(.teacher, size: 140)
                            .padding(.top, Theme.Spacing.lg)

                        VStack(spacing: Theme.Spacing.xs) {
                            Text("What are you brewing toward?")
                                .font(Theme.Font.title)
                                .foregroundStyle(Theme.Color.textPrimary)
                                .multilineTextAlignment(.center)

                            Text("Pick anything that matters — we'll use these to score every plant you scan.")
                                .font(Theme.Font.body)
                                .foregroundStyle(Theme.Color.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.Spacing.lg)
                        }
                    }

                    GoalChipGrid(
                        presets: Self.presets,
                        selected: Set(viewModel.draftGoals.map(\.name)),
                        onTap: toggle(_:)
                    )
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Bottom padding so chips sit clear of the pinned button.
                    Spacer(minLength: 120)
                }
            }
            .scrollIndicators(.hidden)

            VStack {
                Spacer()
                PrimaryButton(
                    "Continue",
                    isDisabled: viewModel.draftGoals.isEmpty,
                    action: onContinue
                )
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, 64) // clear progress dots
            }
        }
    }

    private func toggle(_ name: String) {
        if viewModel.draftGoals.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            viewModel.removeGoal(named: name)
        } else {
            viewModel.addGoal(named: name)
        }
    }
}

/// Wrapping chip grid. Each chip is a pill with a sage selected ring + glass
/// resting state — `.glass(.capsule)` for the unselected wash, sage fill when
/// selected.
private struct GoalChipGrid: View {
    let presets: [String]
    let selected: Set<String>
    let onTap: (String) -> Void

    var body: some View {
        FlowLayout(spacing: Theme.Spacing.xs) {
            ForEach(presets, id: \.self) { preset in
                let isSelected = selected.contains(where: { $0.caseInsensitiveCompare(preset) == .orderedSame })
                GoalChip(label: preset, isSelected: isSelected) { onTap(preset) }
            }
        }
    }
}

private struct GoalChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(Theme.Font.callout)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? Theme.Color.bone : Theme.Color.forest)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background {
                    if isSelected {
                        Capsule(style: .continuous).fill(Theme.Color.sage)
                    } else {
                        Capsule(style: .continuous)
                            .fill(Color.clear)
                            .glass(.capsule)
                    }
                }
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Theme.Color.sage, lineWidth: isSelected ? 0 : 1.2)
                )
        }
        .buttonStyle(.plain)
        .animation(Theme.Motion.snappy, value: isSelected)
    }
}

/// Local copy of the wrapping flex layout (the existing `WrappingHStack`
/// variant lives in `TagInputField.swift` and is bound to a `Hashable` Item;
/// using a fresh layout here avoids cross-feature coupling).
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                totalWidth = max(totalWidth, rowWidth - spacing)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth - spacing)
        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    let mock = AppDependencies.mock
    let vm = OnboardingViewModel(
        auth: mock.auth,
        healthProfileRepo: mock.healthProfile,
        subscriptions: mock.subscriptions
    )
    GoalsPickerPage(viewModel: vm, onContinue: {})
}
