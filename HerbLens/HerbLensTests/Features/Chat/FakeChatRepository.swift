import Foundation
@testable import HerbLens

/// Test-only `ChatRepository` that yields a caller-supplied script of string chunks and
/// optionally terminates with an injected error. Used to drive `ChatThreadViewModel`
/// deterministically from Swift Testing.
struct FakeChatRepository: ChatRepository, @unchecked Sendable {
    let chunks: [String]
    let terminalError: Error?
    let chunkDelayNanos: UInt64
    let conversationsFixture: [Conversation]
    let messagesFixture: [Message]

    init(
        chunks: [String] = [],
        terminalError: Error? = nil,
        chunkDelayNanos: UInt64 = 1_000_000,
        conversationsFixture: [Conversation] = [],
        messagesFixture: [Message] = []
    ) {
        self.chunks = chunks
        self.terminalError = terminalError
        self.chunkDelayNanos = chunkDelayNanos
        self.conversationsFixture = conversationsFixture
        self.messagesFixture = messagesFixture
    }

    func conversations(userID: String) async throws -> [Conversation] { conversationsFixture }

    func messages(conversationID: String) async throws -> [Message] { messagesFixture }

    func startConversation(userID: String, contextPlantID: String?) async throws -> Conversation {
        Conversation(
            id: UUID().uuidString,
            userId: userID,
            startedAt: .now,
            lastMessageAt: .now,
            contextPlantId: contextPlantID,
            messages: []
        )
    }

    func send(message: String, to conversationID: String) -> AsyncThrowingStream<String, Error> {
        let chunks = chunks
        let delay = chunkDelayNanos
        let terminalError = terminalError
        return AsyncThrowingStream { continuation in
            let task = Task {
                for chunk in chunks {
                    if Task.isCancelled { break }
                    continuation.yield(chunk)
                    if delay > 0 {
                        try? await Task.sleep(nanoseconds: delay)
                    }
                }
                if let terminalError {
                    continuation.finish(throwing: terminalError)
                } else {
                    continuation.finish()
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// Haptic spy — records the number of times `.tick()` is called.
final class HapticSpy: HapticTicking, @unchecked Sendable {
    private let lock = NSLock()
    private var _count: Int = 0

    var count: Int {
        lock.lock(); defer { lock.unlock() }
        return _count
    }

    func tick() {
        lock.lock(); defer { lock.unlock() }
        _count += 1
    }
}

/// Minimal `AuthService` stub — the list view model reads `currentUserID` and nothing else.
struct StubAuth: AuthService {
    let userID: String?
    var currentUserID: String? { get async { userID } }
    func signUp(email: String, password: String) async throws -> UserProfile {
        throw CancellationError()
    }
    func signIn(email: String, password: String) async throws -> UserProfile {
        throw CancellationError()
    }
    func signOut() async throws {}
    func sendMagicLink(email: String) async throws {}
    func verifyEmailOTP(email: String, token: String) async throws -> UserProfile { throw CancellationError() }
    func signInWithApple(idToken: String, nonce: String) async throws -> UserProfile { throw CancellationError() }
    func signInWithGoogle(idToken: String, accessToken: String) async throws -> UserProfile { throw CancellationError() }
    func completeOnboarding(userID: String) async throws {}
}
