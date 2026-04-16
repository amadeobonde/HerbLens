import Foundation
import Supabase

/// Chat history persistence + streaming replies from the `ai-chat` edge function.
///
/// We intentionally hand-roll the SSE parser against `URLSession.bytes(for:).lines` rather
/// than using the supabase-swift helper because the edge function emits `data: {...}`
/// frames the SDK doesn't yet know how to stream. Keeping it here also means the parser
/// is unit-testable without a live server.
public struct SupabaseChatRepository: ChatRepository {
    private let client: SupabaseClient
    private let session: URLSession
    private let baseURL: URL?

    public nonisolated init(
        client: SupabaseClient? = nil,
        session: URLSession = .shared,
        baseURL: URL? = nil
    ) {
        self.client = client ?? SupabaseClientProvider.shared
        self.session = session
        self.baseURL = baseURL
    }

    private var resolvedBaseURL: URL { baseURL ?? AppConfig.supabaseURL }

    public func conversations(userID: String) async throws -> [Conversation] {
        let rows: [ConversationRow] = try await client.from("conversations")
            .select("id, user_id, started_at, last_message_at, context_plant_id")
            .eq("user_id", value: userID)
            .order("last_message_at", ascending: false)
            .execute()
            .value
        return rows.map { $0.toDomain(messages: []) }
    }

    public func messages(conversationID: String) async throws -> [Message] {
        let rows: [MessageRow] = try await client.from("messages")
            .select()
            .eq("conversation_id", value: conversationID)
            .order("timestamp", ascending: true)
            .execute()
            .value
        return rows.map { $0.toDomain() }
    }

    public func startConversation(
        userID: String,
        contextPlantID: String?
    ) async throws -> Conversation {
        let insert = ConversationInsert(userId: userID, contextPlantId: contextPlantID)
        let row: ConversationRow = try await client.from("conversations")
            .insert(insert, returning: .representation)
            .select("id, user_id, started_at, last_message_at, context_plant_id")
            .single()
            .execute()
            .value
        return row.toDomain(messages: [])
    }

    public func send(
        message: String,
        to conversationID: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [session, client] in
                do {
                    try await persistUserMessage(message, conversationID: conversationID)
                    let history = try await self.messages(conversationID: conversationID)
                    let contextPlantID = try await self.fetchContextPlantID(conversationID: conversationID)

                    let request = try await makeStreamRequest(
                        history: history,
                        contextPlantID: contextPlantID
                    )

                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                        throw ChatError.httpStatus(code)
                    }

                    var assembled = ""
                    for try await line in bytes.lines {
                        guard let delta = try Self.parseLine(line) else { continue }
                        if delta.done { break }
                        if let chunk = delta.text {
                            assembled += chunk
                            continuation.yield(chunk)
                        }
                    }

                    try await persistAssistantReply(assembled, conversationID: conversationID)
                    // Opportunistic client-side bump in case the edge fn didn't update it.
                    _ = try? await client.from("conversations")
                        .update(["last_message_at": ISO8601DateFormatter().string(from: Date())])
                        .eq("id", value: conversationID)
                        .execute()

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Internals

    private func persistUserMessage(
        _ content: String,
        conversationID: String
    ) async throws {
        let insert = MessageInsert(conversationId: conversationID, role: "user", content: content)
        try await client.from("messages").insert(insert).execute()
    }

    private func persistAssistantReply(
        _ content: String,
        conversationID: String
    ) async throws {
        guard !content.isEmpty else { return }
        let insert = MessageInsert(conversationId: conversationID, role: "assistant", content: content)
        try await client.from("messages").insert(insert).execute()
    }

    private func fetchContextPlantID(conversationID: String) async throws -> String? {
        let row: ConversationRow = try await client.from("conversations")
            .select("id, user_id, started_at, last_message_at, context_plant_id")
            .eq("id", value: conversationID)
            .single()
            .execute()
            .value
        return row.contextPlantId
    }

    private func makeStreamRequest(
        history: [Message],
        contextPlantID: String?
    ) async throws -> URLRequest {
        let url = resolvedBaseURL.appendingPathComponent("/functions/v1/ai-chat")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        if let token = try? await client.auth.session.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try SupabaseJSON.encoder.encode(
            ChatRequest(
                messages: history.map { ChatMessage(role: $0.role.rawValue, content: $0.content) },
                contextPlantId: contextPlantID,
                stream: true
            )
        )
        return request
    }

    // MARK: - SSE parser (pure, testable)

    nonisolated struct LineEvent: Equatable, Sendable {
        let text: String?
        let done: Bool
        nonisolated static let terminal = LineEvent(text: nil, done: true)
    }

    /// Parses one SSE line (already split on `\n` by `bytes.lines`). Returns nil for
    /// keepalives, comments, or blank separators.
    nonisolated static func parseLine(_ line: String) throws -> LineEvent? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("data: ") else { return nil }
        let payload = String(trimmed.dropFirst("data: ".count))
        if payload == "[DONE]" { return .terminal }
        guard let data = payload.data(using: .utf8) else {
            throw ChatError.malformedEvent(payload)
        }
        struct DeltaEnvelope: Decodable { let delta: String? }
        do {
            let envelope = try JSONDecoder().decode(DeltaEnvelope.self, from: data)
            return LineEvent(text: envelope.delta, done: false)
        } catch {
            throw ChatError.malformedEvent(payload)
        }
    }
}

// MARK: - Row / request DTOs

struct ConversationRow: Decodable {
    let id: String
    let userId: String
    let startedAt: Date
    let lastMessageAt: Date
    let contextPlantId: String?

    func toDomain(messages: [Message]) -> Conversation {
        Conversation(
            id: id,
            userId: userId,
            startedAt: startedAt,
            lastMessageAt: lastMessageAt,
            contextPlantId: contextPlantId,
            messages: messages
        )
    }
}

struct MessageRow: Decodable {
    let id: String
    let role: String
    let content: String
    let timestamp: Date

    func toDomain() -> Message {
        Message(
            id: id,
            role: MessageRole(rawValue: role) ?? .user,
            content: content,
            timestamp: timestamp
        )
    }
}

private struct ConversationInsert: Encodable {
    let userId: String
    let contextPlantId: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case contextPlantId = "context_plant_id"
    }
}

private struct MessageInsert: Encodable {
    let conversationId: String
    let role: String
    let content: String

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case role, content
    }
}

private struct ChatRequest: Encodable {
    let messages: [ChatMessage]
    let contextPlantId: String?
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case messages, stream
        case contextPlantId = "context_plant_id"
    }
}

private struct ChatMessage: Encodable {
    let role: String
    let content: String
}
