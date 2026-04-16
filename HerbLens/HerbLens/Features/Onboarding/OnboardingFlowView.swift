import SwiftUI

/// Root entry point for the onboarding experience. App-level routing should
/// present this view whenever `profile.onboardingCompleted == false`.
///
/// B5 reskin: this thin wrapper now hands off to `OnboardingPagerView`, which
/// renders a 4-screen TabView (welcome → goals → allergies/meds → final).
/// The previous email/OTP flow + 5-step wizard files are kept on disk for
/// instance C1's auth sequencing but are no longer routed through here.
public struct OnboardingFlowView: View {
    var onFinished: () -> Void

    public init(onFinished: @escaping () -> Void = {}) {
        self.onFinished = onFinished
    }

    public var body: some View {
        OnboardingPagerView(onFinished: onFinished)
    }
}

#Preview {
    OnboardingFlowView()
        .environment(\.dependencies, .mock)
}
