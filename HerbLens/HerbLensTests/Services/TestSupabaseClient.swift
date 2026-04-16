import Foundation
import Supabase
@testable import HerbLens

/// A throwaway `SupabaseClient` used only to satisfy Live service initializers in tests
/// whose code paths don't actually invoke the client (e.g. the edge-function-only tests).
/// The URL is intentionally invalid so any accidental network call fails fast.
enum TestSupabaseClient {
    static let noop: SupabaseClient = {
        SupabaseClient(
            supabaseURL: URL(string: "http://localhost.invalid")!,
            supabaseKey: "test-anon-key"
        )
    }()
}
