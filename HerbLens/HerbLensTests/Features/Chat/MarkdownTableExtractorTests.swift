import Foundation
import Testing
@testable import HerbLens

@Suite("MarkdownTableExtractor")
struct MarkdownTableExtractorTests {
    @Test("Plain prose produces a single markdown block")
    func plainProse() {
        let input = "Chamomile is a calming herb.\nIt pairs well with lavender."
        let blocks = MarkdownTableExtractor.extract(from: input)
        #expect(blocks.count == 1)
        if case .markdown(let text) = blocks.first {
            #expect(text == input)
        } else {
            Issue.record("Expected a markdown block")
        }
    }

    @Test("Extracts a single table between prose")
    func extractsSingleTable() {
        let input = """
        Chamomile interactions:

        | Condition | Severity |
        | --- | --- |
        | Blood thinners | High |
        | Pregnancy | Moderate |

        Let me know if you want brewing tips.
        """
        let blocks = MarkdownTableExtractor.extract(from: input)
        #expect(blocks.count == 3)
        guard blocks.count == 3 else { return }
        if case .markdown(let before) = blocks[0] {
            #expect(before.contains("Chamomile interactions"))
        } else {
            Issue.record("Expected leading markdown block")
        }
        if case .table(let header, let rows) = blocks[1] {
            #expect(header == ["Condition", "Severity"])
            #expect(rows == [["Blood thinners", "High"], ["Pregnancy", "Moderate"]])
        } else {
            Issue.record("Expected a table block")
        }
        if case .markdown(let after) = blocks[2] {
            #expect(after.contains("brewing tips"))
        } else {
            Issue.record("Expected trailing markdown block")
        }
    }

    @Test("A pipe row without a separator stays as markdown")
    func malformedTableStaysAsMarkdown() {
        let input = """
        | This is prose with a | pipe but no separator |
        And more text.
        """
        let blocks = MarkdownTableExtractor.extract(from: input)
        #expect(blocks.count == 1)
        if case .markdown(let text) = blocks.first {
            #expect(text == input)
        } else {
            Issue.record("Expected a single markdown block")
        }
    }

    @Test("Tables without leading pipes parse equivalently")
    func tablesWithoutLeadingPipes() {
        let input = """
        Condition | Severity
        --- | ---
        Blood thinners | High
        """
        let blocks = MarkdownTableExtractor.extract(from: input)
        #expect(blocks.count == 1)
        if case .table(let header, let rows) = blocks.first {
            #expect(header == ["Condition", "Severity"])
            #expect(rows == [["Blood thinners", "High"]])
        } else {
            Issue.record("Expected a table block")
        }
    }

    @Test("Empty input returns no blocks")
    func emptyInput() {
        #expect(MarkdownTableExtractor.extract(from: "").isEmpty)
    }
}
