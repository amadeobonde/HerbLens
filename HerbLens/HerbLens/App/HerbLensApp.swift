import SwiftUI

@main
struct HerbLensApp: App {
    // Instance 2 (Services/Live) will replace this with `AppDependencies.live(...)` once
    // the Supabase-backed services land. Until then we boot against the in-memory mocks so
    // the full feature pipeline (Instances 3–10) can develop against a working app shell.
    private let dependencies: AppDependencies = .mock

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.dependencies, dependencies)
        }
    }
}
