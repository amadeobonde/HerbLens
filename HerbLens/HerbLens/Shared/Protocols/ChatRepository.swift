import Foundation

public protocol ChatRepository: Sendable {
    func conversations(userID: String) async throws -> [Conversation]
    func messages(conversationID: String) async throws -> [Message]
    func startConversation(userID: String, contextPlantID: String?) async throws -> Conversation
    func send(message: String, to conversationID: String) -> AsyncThrowingStream<String, Error>
}
