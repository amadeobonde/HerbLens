import SwiftUI

/// Row of suggested prompts that deep-link into the Chat feature with a plant context.
/// Parent decides where the closure routes — for free-tier users it's the paywall, for
/// premium it's the Bamboo thread. HerbProfile itself stays tier-agnostic here.
struct AskTab: View {
    let plant: Plant
    let onAskAboutPlant: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            header

            if !plant.suggestedPrompts.isEmpty {
                SuggestedPromptsList(prompts: plant.suggestedPrompts) { _ in
                    onAskAboutPlant(plant.id)
                }
            }
            askButton
        }
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.title3)
                .foregroundStyle(Theme.Color.sage)
            VStack(alignment: .leading, spacing: 2) {
                Text("Ask Bamboo about \(plant.commonName)")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("Premium AI herbalist with context on your health profile.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
    }

    private var askButton: some View {
        Button {
            onAskAboutPlant(plant.id)
        } label: {
            HStack {
                Text("Start a new conversation")
                    .font(Theme.Font.callout)
                Spacer()
                Image(systemName: "arrow.up.right")
            }
            .foregroundStyle(Theme.Color.bone)
            .padding(.horizontal, Theme.Spacing.md)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(Theme.Color.forest))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask Bamboo about \(plant.commonName)")
    }
}

private struct SuggestedPromptsList: View {
    let prompts: [String]
    let onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ForEach(prompts, id: \.self) { prompt in
                Button { onTap(prompt) } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "sparkle")
                            .foregroundStyle(Theme.Color.amber)
                        Text(prompt)
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.textPrimary)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    .padding(Theme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glass(.card)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
