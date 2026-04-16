import SwiftUI

struct CodeEntryView: View {
    @Bindable var viewModel: OnboardingViewModel
    let email: String

    @State private var code: String = ""
    @State private var showResendToast: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Image("bamboo-sleeping")
                .resizable()
                .scaledToFit()
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.Spacing.xl)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Check your email")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("We sent a 6-digit code to \(email). Enter it below or tap the link in your email.")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
            }

            TextField("000000", text: $code)
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .kerning(4)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .onChange(of: code) { _, newValue in
                    let digits = String(newValue.filter(\.isNumber).prefix(6))
                    if digits != newValue { code = digits }
                    if digits.count == 6 {
                        submit(digits)
                    }
                }
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.Color.bone)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Theme.Color.sage.opacity(0.4), lineWidth: 1)
                        )
                )

            Button {
                Task {
                    await viewModel.submitEmail(email)
                    showResendToast = true
                    try? await Task.sleep(for: .seconds(2))
                    showResendToast = false
                }
            } label: {
                Text(showResendToast ? "Sent another one" : "Didn't get it? Resend")
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.forest)
            }
            .buttonStyle(.plain)

            Spacer()

            OnboardingSecondaryButton(title: "Use a different email") {
                viewModel.goBack()
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.lg)
        .background(Theme.Color.background.ignoresSafeArea())
        .onAppear { focused = true }
    }

    private func submit(_ code: String) {
        Task { await viewModel.verifyCode(code) }
    }
}
