import SwiftUI

/// Shared header + footer chrome for the 5-step wizard. Owns the progress bar,
/// the back affordance, and the continue/skip footer. Step content slots in
/// as the `content` builder.
struct WizardChrome<Content: View>: View {
    @Bindable var viewModel: OnboardingViewModel
    let step: OnboardingWizardStep
    var canSkip: Bool = false
    var continueEnabled: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.sm) {
                    if step.previous != nil {
                        Button {
                            viewModel.goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.Color.forest)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Theme.Color.sage.opacity(0.12)))
                        }
                        .buttonStyle(.plain)
                    }
                    StepProgressBar(currentStep: step.displayIndex, totalSteps: OnboardingWizardStep.total)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Step \(step.displayIndex) of \(OnboardingWizardStep.total)")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                    Text(step.title)
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text(step.subtitle)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }

            content()

            Spacer(minLength: Theme.Spacing.md)

            VStack(spacing: Theme.Spacing.xs) {
                OnboardingPrimaryButton(
                    title: step.next == nil ? "Finish" : "Continue",
                    isLoading: viewModel.isBusy,
                    isEnabled: continueEnabled,
                    action: { viewModel.advanceWizard() }
                )
                if canSkip {
                    OnboardingSecondaryButton(title: "Skip for now") {
                        viewModel.advanceWizard()
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Color.background.ignoresSafeArea())
    }
}
