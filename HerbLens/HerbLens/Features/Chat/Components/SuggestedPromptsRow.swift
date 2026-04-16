import SwiftUI

/// Horizontal scroller of suggested-prompt chips. Shown when a plant-context conversation
/// is empty — tapping a chip inserts the prompt into the input. The scroller fades out
/// once the conversation has messages to avoid visual clutter.
struct SuggestedPromptsRow: View {
    let prompts: [String]
    let onTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        onTap(prompt)
                    } label: {
                        Text(prompt)
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.forest)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(Theme.Color.sage.opacity(0.18), in: Capsule())
                            .overlay(Capsule().stroke(Theme.Color.sage.opacity(0.45), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}
