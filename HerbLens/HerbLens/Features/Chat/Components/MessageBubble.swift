import SwiftUI

/// A single chat bubble. Role controls layout and surface:
/// - `.user` — right-aligned forest-green bubble with bone text.
/// - `.assistant` — left-aligned glass card with a Bamboo avatar and markdown content.
/// When `isStreaming` is true, a blinking caret is rendered at the tail.
struct MessageBubble: View {
    let role: MessageRole
    let content: String
    var isStreaming: Bool = false

    var body: some View {
        switch role {
        case .user: userBubble
        case .assistant: assistantBubble
        }
    }

    private var userBubble: some View {
        HStack {
            Spacer(minLength: Theme.Spacing.lg)
            Text(content)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.bone)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Color.forest, in: userBubbleShape)
        }
    }

    private var userBubbleShape: some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: 18,
            bottomLeadingRadius: 18,
            bottomTrailingRadius: 4,
            topTrailingRadius: 18
        )
    }

    private var assistantBubble: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
            BambooAvatarView(size: 28)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                MarkdownRenderer(
                    blocks: MarkdownTableExtractor.extract(from: displayContent)
                )
                if isStreaming {
                    Text("▍")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.forest)
                        .opacity(0.6)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .glass(.card)
            Spacer(minLength: Theme.Spacing.lg)
        }
    }

    private var displayContent: String {
        content.isEmpty ? " " : content
    }
}
