import Foundation

/// Shared, typed error surface for live services. Feature instances pattern-match
/// these to drive UI.
public enum ServiceError: Error, Equatable, Sendable {
    case unauthenticated
    case decodingFailed(String)
    case httpStatus(Int, body: String?)
    case malformedURL
}

/// Raised by `SupabaseChatRepository` during SSE streaming.
public enum ChatError: Error, Equatable, Sendable {
    case httpStatus(Int)
    case malformedEvent(String)
}
