import SwiftUI

struct EmailEntryView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var email: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Image("bamboo-canonical")
                .resizable()
                .scaledToFit()
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.Spacing.xl)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Let's get you set up")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("Enter your email and we'll send you a 6-digit code.")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
            }

            TextField("you@example.com", text: $email)
                .font(Theme.Font.body)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
                .submitLabel(.continue)
                .onSubmit { submit() }
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.Color.bone)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Theme.Color.sage.opacity(0.4), lineWidth: 1)
                        )
                )

            Spacer()

            OnboardingPrimaryButton(
                title: "Send code",
                isLoading: viewModel.isBusy,
                isEnabled: !email.trimmingCharacters(in: .whitespaces).isEmpty,
                action: submit
            )
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.lg)
        .background(Theme.Color.background.ignoresSafeArea())
        .onAppear { focused = true }
    }

    private func submit() {
        let captured = email
        Task { await viewModel.submitEmail(captured) }
    }
}
