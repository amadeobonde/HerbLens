import Foundation

/// Reads build-time configuration from Info.plist (populated by `.xcconfig`).
/// Values are supplied by `Config/Debug.xcconfig` / `Config/Release.xcconfig`, which are
/// gitignored. Never hardcode secrets — decompilation tools extract them trivially.
///
/// Contract (`CLAUDE.md` §6):
/// - `SUPABASE_URL` / `SUPABASE_ANON_KEY` — required
/// - `REVENUECAT_API_KEY` — required at first subscription call
/// - `POSTHOG_API_KEY` / `POSTHOG_HOST` — optional, owned by a later instance
public enum AppConfig {
    public nonisolated static var supabaseURL: URL {
        guard let raw = infoValue("SUPABASE_URL"), let url = URL(string: raw) else {
            fatalError("SUPABASE_URL missing or malformed in Info.plist — check Debug.xcconfig / Release.xcconfig.")
        }
        return url
    }

    public nonisolated static var supabaseAnonKey: String {
        guard let key = infoValue("SUPABASE_ANON_KEY"), !key.isEmpty else {
            fatalError("SUPABASE_ANON_KEY missing from Info.plist — check Debug.xcconfig / Release.xcconfig.")
        }
        return key
    }

    public nonisolated static var revenueCatKey: String {
        guard let key = infoValue("REVENUECAT_API_KEY"), !key.isEmpty else {
            fatalError("REVENUECAT_API_KEY missing from Info.plist — check Debug.xcconfig / Release.xcconfig.")
        }
        return key
    }

    public nonisolated static var posthogKey: String? { infoValue("POSTHOG_API_KEY") }
    public nonisolated static var posthogHost: String? { infoValue("POSTHOG_HOST") }

    private nonisolated static func infoValue(_ key: String) -> String? {
        // `.xcconfig` strings reach Info.plist as-is; `$()` substitutions were resolved at build time.
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }
}
