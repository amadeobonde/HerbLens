import SwiftUI

/// Low-confidence helper: horizontally scrolling chip row of suggested matches so the
/// user can confirm the correct plant themselves.
struct CandidateChipsRow: View {
    let candidates: [Plant]
    let selectedID: String?
    let onSelect: (Plant) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Not quite sure — tap the match")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(candidates) { plant in
                        chip(for: plant)
                    }
                }
                .padding(.vertical, Theme.Spacing.xxs)
            }
        }
    }

    @ViewBuilder
    private func chip(for plant: Plant) -> some View {
        let selected = plant.id == selectedID
        Button {
            onSelect(plant)
        } label: {
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: selected ? "checkmark.circle.fill" : "leaf.fill")
                    .foregroundStyle(selected ? Theme.Color.bone : Theme.Color.forest)
                Text(plant.commonName)
                    .font(Theme.Font.callout)
                    .foregroundStyle(selected ? Theme.Color.bone : Theme.Color.textPrimary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule().fill(selected ? Theme.Color.forest : Theme.Color.bone.opacity(0.6))
            )
            .overlay(
                Capsule().stroke(selected ? Color.clear : Theme.Color.forest.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
