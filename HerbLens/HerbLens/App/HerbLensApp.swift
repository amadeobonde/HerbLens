import SwiftUI

@main
struct HerbLensApp: App {
    private let dependencies: AppDependencies = .mock
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingFlowView {
                        hasCompletedOnboarding = true
                    }
                }
            }
            .environment(\.dependencies, dependencies)
        }
    }
}
