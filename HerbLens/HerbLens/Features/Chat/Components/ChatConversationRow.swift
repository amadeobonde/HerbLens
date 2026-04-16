import SwiftUI

/// One row in the conversation list. The row is wrapped in a subtle glass card and shows
/// the contextual plant thumbnail (if any), an excerpt of the first user message, the
/// plant subtitle, and a relative timestamp. Free chat (no plant context) falls back to
/// the Bamboo mascot avatar so every row keeps a consistent visual anchor.
struct ChatConversationRow: View {
    let conversation: Conversation
    let plantName: String?
    var plantThumbnailURL: URL? = nil

    var body: some View {
        GlassCard(tone: .subtle) {
            HStack(alignment: .center, spacing: Theme.Spacing.sm) {
                thumbnail

                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(title)
                        .font(Theme.Font.callout)
                        .foregroundStyle(Theme.Color.textPrimary)
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
            .contentShape(Rectangle())
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = plantThumbnailURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Theme.Color.sage.opacity(0.25)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .overlay(Circle().stroke(Theme.Color.sage.opacity(0.25), lineWidth: 1))
        } else {
            MascotBadge(.teacher, size: 44)
        }
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
