import SwiftUI

/// The send bar at the bottom of a thread view. The TextField is a glass capsule that
/// grows up to six lines; the send action is a small sage capsule that mirrors the filled
/// `PrimaryButton` variant. Disabled while a stream is in flight or the draft is empty.
struct ChatInputBar: View {
    @Binding var draft: String
    let canSend: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: Theme.Spacing.xs) {
            TextField("Ask Bamboo…", text: $draft, axis: .vertical)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textPrimary)
                .lineLimit(1...6)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .glass(.capsule)

            sendButton
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var sendButton: some View {
        Button(action: onSend) {
            Image(systemName: "arrow.up")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.Color.bone)
                .frame(width: 44, height: 44)
                .background(
                    canSend ? Theme.Color.sage : Theme.Color.sage.opacity(0.35),
                    in: Circle()
                )
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
        .opacity(canSend ? 1.0 : 0.7)
        .animation(Theme.Motion.snappy, value: canSend)
        .accessibilityLabel("Send message")
    }
}
