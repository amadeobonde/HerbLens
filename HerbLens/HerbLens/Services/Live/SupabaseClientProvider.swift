import Foundation
import Supabase

/// Single entry point to the Supabase client and the shared JSON codec used by every
/// live repository. The client is lazily built on first access from `AppConfig`, so tests
/// that never call `.shared` never touch the network layer.
///
/// Tests should call `configure(url:anonKey:)` at setup time to inject a predictable URL.
public enum SupabaseClientProvider {
    nonisolated(unsafe) private static var overrideClient: SupabaseClient?
    nonisolated(unsafe) private static var overrideURL: URL?
    nonisolated(unsafe) private static var overrideAnonKey: String?

    public nonisolated static var shared: SupabaseClient {
        if let overrideClient { return overrideClient }
        let client = SupabaseClient(
            supabaseURL: overrideURL ?? AppConfig.supabaseURL,
            supabaseKey: overrideAnonKey ?? AppConfig.supabaseAnonKey
        )
        overrideClient = client
        return client
    }

    /// Called from `AppDependencies.live(...)` to let the caller pin the URL/key pair
    /// (e.g. a UI-test bundle pointing at a staging project).
    public nonisolated static func configure(url: URL, anonKey: String) {
        overrideURL = url
        overrideAnonKey = anonKey
        overrideClient = nil // force rebuild on next access
    }

    /// Used by tests only: inject a pre-built client (e.g. with a mocked session).
    public nonisolated static func inject(client: SupabaseClient) {
        overrideClient = client
    }

    /// Current user's Supabase JWT for authenticated edge-function calls.
    public nonisolated static func currentAccessToken() async throws -> String {
        do {
            let session = try await shared.auth.session
            return session.accessToken
        } catch {
            throw ServiceError.unauthenticated
        }
    }
}

/// Shared JSON decoder/encoder — snake_case → camelCase and ISO8601 dates, matching how
/// Supabase PostgREST returns rows and how edge functions emit JSON.
public enum SupabaseJSON {
    public static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601WithFractional
        return d
    }()

    public static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601WithFractional
        return e
    }()
}

private extension JSONDecoder.DateDecodingStrategy {
    /// Supabase emits timestamps like `2026-04-15T12:34:56.123456+00:00` — the standard
    /// `.iso8601` strategy rejects fractional seconds, so we use a custom formatter.
    static let iso8601WithFractional: JSONDecoder.DateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if let date = ISO8601Formatter.withFractional.date(from: raw) { return date }
        if let date = ISO8601Formatter.plain.date(from: raw) { return date }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unrecognized date format: \(raw)"
        )
    }
}

private extension JSONEncoder.DateEncodingStrategy {
    static let iso8601WithFractional: JSONEncoder.DateEncodingStrategy = .custom { date, encoder in
        var container = encoder.singleValueContainer()
        try container.encode(ISO8601Formatter.withFractional.string(from: date))
    }
}

private enum ISO8601Formatter {
    nonisolated(unsafe) static let withFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    nonisolated(unsafe) static let plain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
