import SwiftUI

/// Top-level onboarding flow rendered as a 4-page horizontal pager. Pages, in order:
/// `welcome` → `goals` → `allergiesMeds` → `final`. Forward navigation is driven
/// by the call-to-action button on each page; backward navigation works via the
/// native page-style swipe. Sage progress dots ride at the bottom.
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
                    onContinue: { advance(to: .goals) },
                    onSkip: { jumpToFinal() }
                )
                .tag(OnboardingPage.welcome)

                GoalsPickerPage(
                    viewModel: viewModel,
                    onContinue: { advance(to: .allergiesMeds) }
                )
                .tag(OnboardingPage.goals)

                AllergiesMedicationsPage(
                    viewModel: viewModel,
                    onContinue: { advance(to: .final) },
                    onSkip: { advance(to: .final) }
                )
                .tag(OnboardingPage.allergiesMeds)

                FinalPage(
                    viewModel: viewModel,
                    onTakeScan: {
                        Task { await finishAndDismiss(viewModel: viewModel) }
                    }
                )
                .tag(OnboardingPage.final)
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

    private func jumpToFinal() {
        withAnimation(Theme.Motion.gentle) {
            page = .final
        }
    }

    private func finishAndDismiss(viewModel: OnboardingViewModel) async {
        // Best-effort: persist the draft profile if the auth session exists.
        // The pager itself doesn't gate finalization on a session — instance C1's
        // navigation layer is responsible for sequencing auth before/after.
        await viewModel.finalize()
        onFinished()
    }
}

/// Identifier for each pager page. Raw values index the dot-progress view.
enum OnboardingPage: Int, CaseIterable, Hashable {
    case welcome = 0
    case goals
    case allergiesMeds
    case final

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
