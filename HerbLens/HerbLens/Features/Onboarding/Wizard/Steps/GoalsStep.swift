import SwiftUI

struct GoalsStep: View {
    @Bindable var viewModel: OnboardingViewModel

    private static let presets: [String] = [
        "Sleep", "Digestive", "Stress", "Immunity",
        "Skin", "Pain", "Energy", "Focus"
    ]

    var body: some View {
        WizardChrome(
            viewModel: viewModel,
            step: .goals,
            canSkip: false,
            continueEnabled: !viewModel.draftGoals.isEmpty
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Tap to select — drag to rank by priority")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)

                FlowingGoalGrid(
                    presets: Self.presets,
                    selected: Set(viewModel.draftGoals.map(\.name)),
                    onTap: toggle(_:)
                )

                if !viewModel.draftGoals.isEmpty {
                    Text("Your priorities")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .padding(.top, Theme.Spacing.sm)

                    List {
                        ForEach(viewModel.draftGoals) { goal in
                            HStack(spacing: Theme.Spacing.sm) {
                                Text("\((viewModel.draftGoals.firstIndex(of: goal) ?? 0) + 1)")
                                    .font(Theme.Font.captionMono)
                                    .foregroundStyle(Theme.Color.forest)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(Theme.Color.sage.opacity(0.18)))
                                Text(goal.name)
                                    .font(Theme.Font.callout)
                                    .foregroundStyle(Theme.Color.textPrimary)
                                Spacer()
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(Theme.Color.textSecondary.opacity(0.5))
                            }
                            .listRowBackground(Color.clear)
                        }
                        .onMove { source, destination in
                            viewModel.moveGoal(from: source, to: destination)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.editMode, .constant(.active))
                    .frame(minHeight: CGFloat(viewModel.draftGoals.count) * 48)
                }
            }
        }
    }

    private func toggle(_ name: String) {
        if viewModel.draftGoals.contains(where: { $0.name == name }) {
            viewModel.removeGoal(named: name)
        } else {
            viewModel.addGoal(named: name)
        }
    }
}

private struct FlowingGoalGrid: View {
    let presets: [String]
    let selected: Set<String>
    let onTap: (String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.xs),
        GridItem(.flexible(), spacing: Theme.Spacing.xs)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.xs) {
            ForEach(presets, id: \.self) { preset in
                let isSelected = selected.contains(preset)
                Button { onTap(preset) } label: {
                    Text(preset)
                        .font(Theme.Font.callout)
                        .foregroundStyle(isSelected ? Theme.Color.bone : Theme.Color.forest)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? Theme.Color.sage : Theme.Color.sage.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
