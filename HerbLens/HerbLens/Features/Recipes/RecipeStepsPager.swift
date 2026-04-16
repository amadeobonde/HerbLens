import SwiftUI

/// Swipe-between-steps component. Last step exposes the "mark as made" CTA
/// so users wrap the brew journey in a single gesture path.
struct RecipeStepsPager: View {
    let steps: [RecipeStep]
    let isMade: Bool
    let onToggleMade: () -> Void

    @State private var currentIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Step \(min(currentIndex + 1, steps.count)) of \(steps.count)")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)

            TabView(selection: $currentIndex) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    stepCard(step)
                        .tag(index)
                        .padding(.horizontal, Theme.Spacing.xxs)
                }
                markAsMadePage
                    .tag(steps.count)
                    .padding(.horizontal, Theme.Spacing.xxs)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(minHeight: 240)

            pageDots
        }
    }

    private func stepCard(_ step: RecipeStep) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("\(step.stepNumber)")
                .font(Theme.Font.display)
                .foregroundStyle(Theme.Color.amber)
            Text(step.instruction)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textPrimary)
            if let tip = step.tip {
                HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Theme.Color.amber)
                    Text(tip)
                        .font(Theme.Font.callout)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .padding(Theme.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glass(.subtle)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(.card)
    }

    private var markAsMadePage: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: isMade ? "checkmark.seal.fill" : "checkmark.seal")
                .font(.system(size: 48))
                .foregroundStyle(isMade ? Theme.Color.sage : Theme.Color.forest)
            Text(isMade ? "Made it" : "Wrap it up")
                .font(Theme.Font.title)
                .foregroundStyle(Theme.Color.textPrimary)
            Button(action: onToggleMade) {
                Text(isMade ? "Unmark" : "Mark as made")
                    .font(Theme.Font.callout)
                    .fontWeight(.semibold)
                    .padding(.vertical, Theme.Spacing.sm)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .background(isMade ? Theme.Color.ember : Theme.Color.forest, in: .capsule)
                    .foregroundStyle(Theme.Color.bone)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .glass(.card)
    }

    private var pageDots: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            ForEach(0...steps.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? Theme.Color.forest : Theme.Color.sage.opacity(0.35))
                    .frame(width: index == currentIndex ? 16 : 6, height: 6)
                    .animation(.spring(duration: 0.2), value: currentIndex)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    RecipeStepsPager(
        steps: RecipePreviewFixtures.localTinctures[0].steps,
        isMade: false,
        onToggleMade: {}
    )
    .padding()
    .background(Theme.Color.bone)
}
