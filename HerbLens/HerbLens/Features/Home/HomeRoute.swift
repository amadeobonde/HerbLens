import Foundation

/// Routes pushed onto the Home `NavigationStack`. Carries plant ID rather than the full
/// `Plant` value so SwiftUI's path serialization stays cheap and state restoration
/// doesn't re-encode nested recipes/warnings on every push.
public nonisolated enum HomeRoute: Hashable, Sendable {
    case plant(id: String)
}
