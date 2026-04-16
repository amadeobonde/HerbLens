import Foundation

/// Shared, typed error surface for live services. Feature instances pattern-match
/// these to drive UI — for example, `ScanError.quotaExceeded` triggers the paywall.
public enum ServiceError: Error, Equatable, Sendable {
    case unauthenticated
    case decodingFailed(String)
    case httpStatus(Int, body: String?)
    case malformedURL
}

/// Raised by `SupabaseScansRepository` when a free-tier user hits the daily cap.
public enum ScanError: Error, Equatable, Sendable {
    case quotaExceeded(limit: Int)
}

/// Raised by `SupabaseChatRepository` during SSE streaming.
public enum ChatError: Error, Equatable, Sendable {
    case httpStatus(Int)
    case malformedEvent(String)
}
