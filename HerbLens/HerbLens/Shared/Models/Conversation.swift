import Foundation

public nonisolated enum MessageRole: String, Codable, Sendable, CaseIterable, Hashable {
    case user
    case assistant
}

public nonisolated struct Message: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let role: MessageRole
    public let content: String
    public let timestamp: Date

    public init(id: String, role: MessageRole, content: String, timestamp: Date) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

public nonisolated struct Conversation: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let userId: String
    public let startedAt: Date
    public let lastMessageAt: Date
    public let contextPlantId: String?
    public let messages: [Message]

    public init(
        id: String,
        userId: String,
        startedAt: Date,
        lastMessageAt: Date,
        contextPlantId: String? = nil,
        messages: [Message]
    ) {
        self.id = id
        self.userId = userId
        self.startedAt = startedAt
        self.lastMessageAt = lastMessageAt
        self.contextPlantId = contextPlantId
        self.messages = messages
    }
}
