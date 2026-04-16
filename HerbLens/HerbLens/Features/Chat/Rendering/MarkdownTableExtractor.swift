import Foundation

/// Splits raw markdown into an ordered list of `ChatContentBlock`s, extracting GFM-style
/// pipe tables so the renderer can lay them out with SwiftUI `Grid` instead of bare text.
///
/// A table is detected by a header row followed by a separator row matching
/// `^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$`. Anything else passes through
/// unchanged as a `.markdown` block.
nonisolated enum MarkdownTableExtractor {
    static func extract(from content: String) -> [ChatContentBlock] {
        guard !content.isEmpty else { return [] }
        let lines = content.components(separatedBy: "\n")
        var blocks: [ChatContentBlock] = []
        var prosePending: [String] = []
        var index = 0

        func flushProse() {
            guard !prosePending.isEmpty else { return }
            let text = prosePending.joined(separator: "\n")
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                blocks.append(.markdown(text))
            }
            prosePending.removeAll(keepingCapacity: true)
        }

        while index < lines.count {
            let header = lines[index]
            let separatorIndex = index + 1
            if separatorIndex < lines.count,
               looksLikePipeRow(header),
               isSeparatorRow(lines[separatorIndex]) {
                flushProse()
                let headerCells = splitPipeRow(header)
                var rows: [[String]] = []
                var cursor = separatorIndex + 1
                while cursor < lines.count, looksLikePipeRow(lines[cursor]) {
                    rows.append(splitPipeRow(lines[cursor]))
                    cursor += 1
                }
                blocks.append(.table(header: headerCells, rows: rows))
                index = cursor
            } else {
                prosePending.append(header)
                index += 1
            }
        }
        flushProse()
        return blocks
    }

    // MARK: - Helpers

    private static func looksLikePipeRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("|") else { return false }
        return trimmed.count > 1
    }

    private static func isSeparatorRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        let stripped = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        let cells = stripped.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        guard cells.count >= 2 else { return false }
        for cell in cells {
            guard !cell.isEmpty else { return false }
            let hyphens = cell.filter { $0 == "-" }
            guard hyphens.count >= 3 else { return false }
            let allowed: Set<Character> = [":", "-"]
            guard cell.allSatisfy({ allowed.contains($0) }) else { return false }
        }
        return true
    }

    private static func splitPipeRow(_ line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let stripped = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        return stripped
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
}
