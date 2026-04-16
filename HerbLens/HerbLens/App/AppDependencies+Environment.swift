import SwiftUI

private struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue: AppDependencies = .mock
}

public extension EnvironmentValues {
    /// Access the current `AppDependencies` from any SwiftUI view via
    /// `@Environment(\.dependencies)`. Defaults to `.mock` so previews "just work".
    var dependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
