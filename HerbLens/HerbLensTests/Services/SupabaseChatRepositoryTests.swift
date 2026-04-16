import Foundation
import Testing
@testable import HerbLens

/// The SSE parser is the one place where a subtle off-by-one would silently corrupt
/// every streamed response, so we cover it exhaustively at the pure-function layer.
@Suite("SSE parser")
struct SSEParserTests {
    @Test("parses a normal delta frame")
    func parsesDelta() throws {
        let event = try SupabaseChatRepository.parseLine("data: {\"delta\":\"Hello\"}")
        #expect(event == .init(text: "Hello", done: false))
    }

    @Test("recognizes the terminal [DONE] sentinel")
    func recognizesTerminal() throws {
        let event = try SupabaseChatRepository.parseLine("data: [DONE]")
        #expect(event == .terminal)
    }

    @Test("ignores keepalives and SSE comments")
    func ignoresKeepalives() throws {
        #expect(try SupabaseChatRepository.parseLine("") == nil)
        #expect(try SupabaseChatRepository.parseLine(": keepalive") == nil)
        #expect(try SupabaseChatRepository.parseLine("event: ping") == nil)
    }

    @Test("throws on malformed JSON payload")
    func throwsOnGarbage() {
        #expect(throws: ChatError.self) {
            _ = try SupabaseChatRepository.parseLine("data: not-json")
        }
    }

    @Test("accepts empty delta without failing the stream")
    func emptyDelta() throws {
        // Some providers emit an initial `{"delta":""}` frame — we should pass it through.
        let event = try SupabaseChatRepository.parseLine("data: {\"delta\":\"\"}")
        #expect(event == .init(text: "", done: false))
    }

    @Test("handles a decoded delta with whitespace around the frame")
    func trimsWhitespace() throws {
        let event = try SupabaseChatRepository.parseLine("  data: {\"delta\":\"A\"}  ")
        #expect(event == .init(text: "A", done: false))
    }
}
