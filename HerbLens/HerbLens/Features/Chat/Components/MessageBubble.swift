import SwiftUI

/// A single chat bubble. Role controls layout and surface:
/// - `.user` — trailing-aligned sage capsule with bone text.
/// - `.assistant` — leading-aligned subtle glass card with a Bamboo mascot avatar and
///   markdown-rendered content. When `isStreaming` is true, a blinking caret is rendered
///   at the tail to mark the live token stream.
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
                .background(Theme.Color.sage, in: Capsule(style: .continuous))
        }
    }

    private var assistantBubble: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
            MascotBadge(.teacher, size: 28)
            GlassCard(tone: .subtle) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    MarkdownRenderer(
                        blocks: MarkdownTableExtractor.extract(from: displayContent)
                    )
                    .foregroundStyle(Theme.Color.textPrimary)
                    if isStreaming {
                        Text("▍")
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.sage)
                            .opacity(0.7)
                    }
                }
            }
            Spacer(minLength: Theme.Spacing.lg)
        }
    }

    private var displayContent: String {
        content.isEmpty ? " " : content
    }
}
