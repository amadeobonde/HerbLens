import Foundation
import Observation

/// Drives `ChatThreadView`. Owns the message list, the live streaming buffer, and the
/// input draft. The live repository persists both user and assistant messages; this
/// view model only manages transient UI state (optimistic user echo, streaming buffer,
/// typing indicator, error banner).
@MainActor
@Observable
final class ChatThreadViewModel {
    private(set) var conversation: Conversation
    private(set) var messages: [Message] = []
    private(set) var streamingBuffer: String = ""
    private(set) var isStreaming: Bool = false
    private(set) var isWaitingForFirstToken: Bool = false
    private(set) var errorBanner: String?
    private(set) var contextPlant: Plant?
    private(set) var bootstrapPhase: Phase = .idle

    var draft: String = ""

    enum Phase: Sendable, Hashable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private let chat: any ChatRepository
    private let plants: any PlantsRepository
    private let haptics: any HapticTicking
    private var streamTask: Task<Void, Never>?

    init(
        conversation: Conversation,
        chat: any ChatRepository,
        plants: any PlantsRepository,
        haptics: any HapticTicking = LiveHapticTicking()
    ) {
        self.conversation = conversation
        self.chat = chat
        self.plants = plants
        self.haptics = haptics
        self.messages = conversation.messages
    }

    func bootstrap() async {
        bootstrapPhase = .loading
        do {
            async let history = chat.messages(conversationID: conversation.id)
            async let plant: Plant? = loadContextPlant()
            let loaded = try await history
            let resolvedPlant = await plant
            messages = loaded
            contextPlant = resolvedPlant
            bootstrapPhase = .loaded
        } catch {
            bootstrapPhase = .failed(Self.friendly(error))
        }
    }

    func send() {
        guard !isStreaming else { return }
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = Message(
            id: UUID().uuidString,
            role: .user,
            content: trimmed,
            timestamp: Date()
        )
        messages.append(userMessage)
        draft = ""
        errorBanner = nil
        streamingBuffer = ""
        isStreaming = true
        isWaitingForFirstToken = true

        streamTask = Task { [weak self] in
            await self?.consumeStream(for: trimmed)
        }
    }

    func cancelStream() {
        streamTask?.cancel()
        streamTask = nil
        if isStreaming {
            isStreaming = false
            isWaitingForFirstToken = false
            streamingBuffer = ""
        }
    }

    func dismissError() {
        errorBanner = nil
    }

    func insertPrompt(_ prompt: String) {
        draft = prompt
    }

    // MARK: - Private

    private func consumeStream(for message: String) async {
        let stream = chat.send(message: message, to: conversation.id)
        do {
            for try await delta in stream {
                if Task.isCancelled { return }
                if isWaitingForFirstToken {
                    isWaitingForFirstToken = false
                    haptics.tick()
                }
                streamingBuffer += delta
            }
            let assembled = streamingBuffer
            streamingBuffer = ""
            isStreaming = false
            isWaitingForFirstToken = false
            if !assembled.isEmpty {
                messages.append(
                    Message(
                        id: UUID().uuidString,
                        role: .assistant,
                        content: assembled,
                        timestamp: Date()
                    )
                )
            }
        } catch {
            if Task.isCancelled { return }
            errorBanner = Self.friendly(error)
            streamingBuffer = ""
            isStreaming = false
            isWaitingForFirstToken = false
        }
    }

    private func loadContextPlant() async -> Plant? {
        guard let id = conversation.contextPlantId else { return nil }
        return try? await plants.plant(id: id)
    }

    nonisolated static func friendly(_ error: Error) -> String {
        if let chatError = error as? ChatError {
            switch chatError {
            case .httpStatus(let code):
                return "Bamboo couldn't respond (status \(code)). Try again."
            case .malformedEvent:
                return "Bamboo got confused mid-sentence. Please retry."
            }
        }
        if let service = error as? ServiceError {
            switch service {
            case .unauthenticated: return "Please sign in again to continue the chat."
            case .httpStatus(let code, _): return "Bamboo couldn't respond (status \(code))."
            case .decodingFailed: return "Bamboo's reply was unreadable. Please retry."
            case .malformedURL: return "Bamboo's server address is misconfigured."
            }
        }
        return "Something went wrong. Please retry."
    }
}
