import Foundation
import Testing
@testable import HerbLens

@Suite("ChatThreadViewModel streaming")
@MainActor
struct ChatThreadViewModelTests {
    @Test("Deltas accumulate into streamingBuffer, then commit to messages on finish")
    func streamingAppendsAndCommits() async {
        let (vm, haptics) = Self.makeViewModel(chunks: ["Hel", "lo ", "world"])
        vm.draft = "Hi"
        vm.send()
        await Self.waitUntilNotStreaming(vm)

        #expect(haptics.count == 1, "Haptic should fire exactly once on the first token")
        #expect(vm.isStreaming == false)
        #expect(vm.streamingBuffer.isEmpty)
        #expect(vm.messages.count == 2, "Optimistic user message + assistant reply")
        #expect(vm.messages.last?.role == .assistant)
        #expect(vm.messages.last?.content == "Hello world")
        #expect(vm.messages.first?.role == .user)
        #expect(vm.messages.first?.content == "Hi")
        #expect(vm.errorBanner == nil)
    }

    @Test("Terminal error surfaces a banner and clears streaming state")
    func terminalErrorSurfacesBanner() async {
        let (vm, _) = Self.makeViewModel(
            chunks: ["Hel"],
            terminalError: ChatError.httpStatus(500)
        )
        vm.draft = "Hi"
        vm.send()
        await Self.waitUntilNotStreaming(vm)

        #expect(vm.isStreaming == false)
        #expect(vm.streamingBuffer.isEmpty)
        #expect(vm.errorBanner != nil)
        #expect(vm.messages.contains { $0.role == .user })
        #expect(!vm.messages.contains { $0.role == .assistant })
    }

    @Test("dismissError clears the banner")
    func dismissErrorClears() async {
        let (vm, _) = Self.makeViewModel(
            chunks: [],
            terminalError: ChatError.httpStatus(503)
        )
        vm.draft = "Hi"
        vm.send()
        await Self.waitUntilNotStreaming(vm)
        #expect(vm.errorBanner != nil)
        vm.dismissError()
        #expect(vm.errorBanner == nil)
    }

    @Test("insertPrompt sets the draft")
    func insertPromptSetsDraft() {
        let (vm, _) = Self.makeViewModel()
        vm.insertPrompt("Tell me about sleep blends")
        #expect(vm.draft == "Tell me about sleep blends")
    }

    @Test("Empty draft is a no-op")
    func emptyDraftNoOp() async {
        let (vm, _) = Self.makeViewModel(chunks: ["nope"])
        vm.draft = "   "
        vm.send()
        #expect(vm.isStreaming == false)
        #expect(vm.messages.isEmpty)
    }

    @Test("cancelStream stops an in-flight stream")
    func cancelStreamStops() async {
        let (vm, _) = Self.makeViewModel(
            chunks: Array(repeating: "x", count: 50),
            chunkDelayNanos: 5_000_000
        )
        vm.draft = "Hi"
        vm.send()
        try? await Task.sleep(nanoseconds: 5_000_000)
        vm.cancelStream()

        #expect(vm.isStreaming == false)
        #expect(vm.streamingBuffer.isEmpty)
    }

    // MARK: - Helpers

    private static func makeViewModel(
        chunks: [String] = [],
        terminalError: Error? = nil,
        chunkDelayNanos: UInt64 = 1_000_000
    ) -> (ChatThreadViewModel, HapticSpy) {
        let conversation = Conversation(
            id: "c-1",
            userId: "u-1",
            startedAt: .now,
            lastMessageAt: .now,
            contextPlantId: nil,
            messages: []
        )
        let chat = FakeChatRepository(
            chunks: chunks,
            terminalError: terminalError,
            chunkDelayNanos: chunkDelayNanos
        )
        let spy = HapticSpy()
        let vm = ChatThreadViewModel(
            conversation: conversation,
            chat: chat,
            plants: UnusedThreadPlantsRepository(),
            haptics: spy
        )
        return (vm, spy)
    }

    private static func waitUntilNotStreaming(
        _ vm: ChatThreadViewModel,
        maxIterations: Int = 500
    ) async {
        for _ in 0..<maxIterations {
            if !vm.isStreaming { return }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }
}

private struct UnusedThreadPlantsRepository: PlantsRepository, @unchecked Sendable {
    func featured() async throws -> [Plant] { [] }
    func plant(id: String) async throws -> Plant {
        throw ServiceError.decodingFailed("plants repo should not be touched in these tests")
    }
    func search(query: String) async throws -> [Plant] { [] }
    func healthScore(for plantID: String, userID: String) async throws -> HealthScore {
        throw ServiceError.decodingFailed("unused")
    }
    func highlightCollections() async throws -> [HighlightCollection] { [] }
}
