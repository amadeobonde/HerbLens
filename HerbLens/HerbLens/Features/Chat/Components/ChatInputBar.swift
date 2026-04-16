import SwiftUI

/// The send bar at the bottom of a thread view. TextField grows up to six lines; the
/// send button is disabled while a stream is in flight or the draft is empty/whitespace.
struct ChatInputBar: View {
    @Binding var draft: String
    let canSend: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: Theme.Spacing.xs) {
            TextField("Ask Bamboo…", text: $draft, axis: .vertical)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.charcoal)
                .lineLimit(1...6)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .glass(.capsule)

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(canSend ? Theme.Color.forest : Theme.Color.sage.opacity(0.4))
            }
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
    }
}
