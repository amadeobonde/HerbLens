import SwiftUI

/// Page 4 of the pager. Celebratory confirmation — Bamboo (celebrating variant)
/// + "You're all set!" + a primary CTA that fires the closure C1's nav layer
/// uses to swap in the main tab navigation.
struct FinalPage: View {
    @Bindable var viewModel: OnboardingViewModel
    let onTakeScan: () -> Void

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Spacer()

                MascotBadge(.celebrating, size: 180)

                VStack(spacing: Theme.Spacing.xs) {
                    Text("You're all set!")
                        .font(Theme.Font.display)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.lg)
                }

                Spacer()

                PrimaryButton("Take a scan", action: onTakeScan)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, 80) // clear progress dots
            }
        }
    }

    private var subtitle: String {
        let goalCount = viewModel.draftGoals.count
        switch goalCount {
        case 0:
            return "Point your camera at any herb and Bamboo will take it from there."
        case 1:
            return "We'll score every plant against your top goal so you brew with intent."
        default:
            return "We'll score every plant against your \(goalCount) goals so you brew with intent."
        }
    }
}

#Preview {
    let mock = AppDependencies.mock
    let vm = OnboardingViewModel(
        auth: mock.auth,
        healthProfileRepo: mock.healthProfile,
        subscriptions: mock.subscriptions
    )
    FinalPage(viewModel: vm, onTakeScan: {})
}
