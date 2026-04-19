import SwiftUI

/// Top-level onboarding flow rendered as a 6-page horizontal pager:
/// welcome → goals → allergies/meds → experience → value prop → account.
/// Forward navigation is driven by the CTA on each page; backward navigation
/// works via the native page-style swipe. Sage progress dots ride at the bottom.
public struct OnboardingPagerView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var page: OnboardingPage = .welcome
    @State private var viewModel: OnboardingViewModel?

    var onFinished: () -> Void

    public init(onFinished: @escaping () -> Void = {}) {
        self.onFinished = onFinished
    }

    public var body: some View {
        Group {
            if let viewModel {
                pagerContent(for: viewModel)
            } else {
                Color.clear
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = OnboardingViewModel(
                    auth: dependencies.auth,
                    healthProfileRepo: dependencies.healthProfile,
                    subscriptions: dependencies.subscriptions
                )
            }
        }
    }

    @ViewBuilder
    private func pagerContent(for viewModel: OnboardingViewModel) -> some View {
        ZStack(alignment: .bottom) {
            Theme.Color.background.ignoresSafeArea()

            TabView(selection: $page) {
                WelcomeView(
                    onContinue: { advance(to: .goals) }
                )
                .tag(OnboardingPage.welcome)

                GoalsPickerPage(
                    viewModel: viewModel,
                    onContinue: { advance(to: .allergiesMeds) }
                )
                .tag(OnboardingPage.goals)

                AllergiesMedicationsPage(
                    viewModel: viewModel,
                    onContinue: { advance(to: .experience) },
                    onSkip: { advance(to: .experience) }
                )
                .tag(OnboardingPage.allergiesMeds)

                ExperienceLevelPage(
                    viewModel: viewModel,
                    onContinue: { advance(to: .valueProp) }
                )
                .tag(OnboardingPage.experience)

                ValuePropPage(
                    onContinue: { advance(to: .account) }
                )
                .tag(OnboardingPage.valueProp)

                AccountPage(
                    viewModel: viewModel,
                    onFinished: onFinished
                )
                .tag(OnboardingPage.account)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            .ignoresSafeArea()

            ProgressDots(currentPage: page)
                .padding(.bottom, Theme.Spacing.md)
        }
        .animation(Theme.Motion.gentle, value: page)
    }

    private func advance(to next: OnboardingPage) {
        withAnimation(Theme.Motion.gentle) {
            page = next
        }
    }
}

/// Identifier for each pager page. Raw values index the dot-progress view.
enum OnboardingPage: Int, CaseIterable, Hashable {
    case welcome = 0
    case goals
    case allergiesMeds
    case experience
    case valueProp
    case account

    static var total: Int { allCases.count }
}

private struct ProgressDots: View {
    let currentPage: OnboardingPage

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(OnboardingPage.allCases, id: \.rawValue) { page in
                let isActive = page.rawValue <= currentPage.rawValue
                Capsule()
                    .fill(isActive ? Theme.Color.sage : Theme.Color.sage.opacity(0.25))
                    .frame(
                        width: page == currentPage ? 18 : 8,
                        height: 8
                    )
                    .animation(Theme.Motion.snappy, value: currentPage)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .glass(.capsule)
        .clipShape(Capsule())
    }
}

#Preview {
    OnboardingPagerView()
        .environment(\.dependencies, .mock)
}
