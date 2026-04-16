import SwiftUI

/// One row in the conversation list. Title is a short excerpt of the first user message
/// (or "New conversation" when empty); subtitle is the context plant name, and the
/// trailing timestamp uses the relative short format.
struct ChatConversationRow: View {
    let conversation: Conversation
    let plantName: String?

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.sm) {
            BambooAvatarView(size: 40)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(title)
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.charcoal)
                    .lineLimit(1)
                Text(subtitle)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(conversation.lastMessageAt.shortRelativeString)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .contentShape(Rectangle())
    }

    private var title: String {
        let firstUserMessage = conversation.messages.first { $0.role == .user }?.content
        guard let firstUserMessage, !firstUserMessage.isEmpty else {
            return "New conversation"
        }
        return String(firstUserMessage.prefix(64))
    }

    private var subtitle: String {
        plantName ?? "General chat"
    }
}
