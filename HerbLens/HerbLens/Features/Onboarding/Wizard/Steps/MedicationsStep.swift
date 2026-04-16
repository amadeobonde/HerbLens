import SwiftUI

struct MedicationsStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        WizardChrome(
            viewModel: viewModel,
            step: .medications,
            canSkip: true
        ) {
            TagInputField(
                tags: $viewModel.draftMedications,
                placeholder: "Add a medication (e.g. Warfarin)"
            )
        }
    }
}
