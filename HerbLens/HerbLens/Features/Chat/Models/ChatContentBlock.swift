import Foundation

/// A single addressable chunk of an assistant message. Assistant replies come through as
/// one string of markdown; the renderer pre-processes that into an ordered list of blocks
/// so tables can be laid out with SwiftUI `Grid` while prose stays as `Text(AttributedString)`.
enum ChatContentBlock: Sendable, Hashable, Identifiable {
    case markdown(String)
    case table(header: [String], rows: [[String]])

    var id: Int {
        var hasher = Hasher()
        switch self {
        case .markdown(let text):
            hasher.combine(0)
            hasher.combine(text)
        case .table(let header, let rows):
            hasher.combine(1)
            hasher.combine(header)
            for row in rows { hasher.combine(row) }
        }
        return hasher.finalize()
    }
}
