import SwiftUI

struct ConditionsStep: View {
    @Bindable var viewModel: OnboardingViewModel

    private static let presets: [String] = [
        "Pregnant",
        "Breastfeeding",
        "High blood pressure",
        "Diabetes",
        "Liver disease",
        "Kidney disease",
        "On anticoagulants"
    ]

    var body: some View {
        WizardChrome(
            viewModel: viewModel,
            step: .conditions,
            canSkip: true
        ) {
            TagInputField(
                tags: $viewModel.draftConditions,
                placeholder: "Add a condition",
                suggestions: Self.presets
            )
        }
    }
}
