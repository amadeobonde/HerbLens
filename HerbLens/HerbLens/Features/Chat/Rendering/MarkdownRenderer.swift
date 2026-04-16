import SwiftUI

/// Renders a list of `ChatContentBlock`s. Prose blocks flow through
/// `Text(AttributedString(markdown:))` (inline-only — preserves whitespace without
/// collapsing lists); table blocks defer to `MarkdownTableView` for Grid layout.
struct MarkdownRenderer: View {
    let blocks: [ChatContentBlock]
    var textColor: Color = Theme.Color.charcoal

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ForEach(blocks) { block in
                switch block {
                case .markdown(let text):
                    markdownText(text)
                case .table(let header, let rows):
                    MarkdownTableView(header: header, rows: rows)
                }
            }
        }
    }

    @ViewBuilder
    private func markdownText(_ text: String) -> some View {
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            Text(attributed)
                .font(Theme.Font.body)
                .foregroundStyle(textColor)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(text)
                .font(Theme.Font.body)
                .foregroundStyle(textColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
