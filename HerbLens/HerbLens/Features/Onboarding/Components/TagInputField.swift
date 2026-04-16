import SwiftUI

/// Chip-style multi-tag input used by allergies / medications / conditions steps.
struct TagInputField: View {
    @Binding var tags: [String]
    let placeholder: String
    var suggestions: [String] = []

    @State private var draft: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if !tags.isEmpty {
                WrappingHStack(items: tags) { tag in
                    TagChip(label: tag) { remove(tag) }
                }
            }

            HStack(spacing: Theme.Spacing.xs) {
                TextField(placeholder, text: $draft)
                    .font(Theme.Font.body)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit { commit() }
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                if !draft.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button("Add") { commit() }
                        .font(Theme.Font.callout)
                        .foregroundStyle(Theme.Color.forest)
                }
            }
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.Color.bone)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.Color.sage.opacity(0.3), lineWidth: 1)
                    )
            )

            if !suggestions.isEmpty {
                let unused = suggestions.filter { candidate in
                    !tags.contains(where: { $0.caseInsensitiveCompare(candidate) == .orderedSame })
                }
                if !unused.isEmpty {
                    Text("Common")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .padding(.top, Theme.Spacing.xs)
                    WrappingHStack(items: unused) { suggestion in
                        Button {
                            add(suggestion)
                        } label: {
                            Text(suggestion)
                                .font(Theme.Font.caption)
                                .foregroundStyle(Theme.Color.forest)
                                .padding(.horizontal, Theme.Spacing.sm)
                                .padding(.vertical, Theme.Spacing.xs)
                                .background(
                                    Capsule().fill(Theme.Color.sage.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func commit() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        add(trimmed)
        draft = ""
    }

    private func add(_ tag: String) {
        guard !tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) else { return }
        tags.append(tag)
    }

    private func remove(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

private struct TagChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Text(label)
                .font(Theme.Font.callout)
                .foregroundStyle(Theme.Color.forest)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Theme.Color.forest.opacity(0.55))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Capsule().fill(Theme.Color.sage.opacity(0.15)))
    }
}

/// Minimal wrapping flex layout for chips. SwiftUI's `Layout` API (iOS 16+) keeps this
/// tight without pulling in an external dependency.
struct WrappingHStack<Item: Hashable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content

    var body: some View {
        FlowLayout(spacing: Theme.Spacing.xs) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                totalWidth = max(totalWidth, rowWidth - spacing)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth - spacing)
        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
