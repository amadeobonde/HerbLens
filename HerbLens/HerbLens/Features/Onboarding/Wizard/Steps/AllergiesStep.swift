import SwiftUI

struct AllergiesStep: View {
    @Bindable var viewModel: OnboardingViewModel

    private static let presets: [String] = [
        "Ragweed", "Pollen", "Tree nuts", "Peanuts",
        "Dairy", "Soy", "Gluten", "Latex"
    ]

    var body: some View {
        WizardChrome(
            viewModel: viewModel,
            step: .allergies,
            canSkip: true
        ) {
            TagInputField(
                tags: $viewModel.draftAllergies,
                placeholder: "Add an allergy",
                suggestions: Self.presets
            )
        }
    }
}
