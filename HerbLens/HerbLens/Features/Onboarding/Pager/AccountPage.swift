import AuthenticationServices
import SwiftUI

struct AccountPage: View {
    @Bindable var viewModel: OnboardingViewModel
    let onFinished: @Sendable () -> Void

    @State private var showEmailFlow = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    private let appleCoordinator = AppleSignInCoordinator()

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    Spacer(minLength: Theme.Spacing.xl)

                    MascotBadge(.celebrating, size: 150)

                    VStack(spacing: Theme.Spacing.xs) {
                        Text("Save Your Progress")
                            .font(Theme.Font.display)
                            .foregroundStyle(Theme.Color.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Create an account to sync your data across devices and never lose your profile.")
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.lg)
                    }

                    VStack(spacing: Theme.Spacing.sm) {
                        SignInWithAppleButton(.continue) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { _ in }
                            .frame(height: 52)
                            .cornerRadius(Theme.Radius.md)
                            .overlay {
                                Button {
                                    Task { await handleAppleSignIn() }
                                } label: {
                                    Color.clear
                                }
                            }

                        googleButton

                        emailButton
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .disabled(isLoading)

                    if let errorMessage {
                        errorBanner(errorMessage)
                            .padding(.horizontal, Theme.Spacing.lg)
                    }

                    if isLoading {
                        ProgressView()
                            .tint(Theme.Color.sage)
                            .padding(.top, Theme.Spacing.sm)
                    }

                    Spacer(minLength: 80)
                }
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showEmailFlow) {
            EmailOTPFlow(viewModel: viewModel) {
                showEmailFlow = false
                Task { await finalizeAndFinish() }
            }
        }
    }

    // MARK: - Auth handlers

    private func handleAppleSignIn() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let result = try await appleCoordinator.signIn()
            _ = try await viewModel.auth.signInWithApple(
                idToken: result.idToken,
                nonce: result.nonce
            )
            await finalizeAndFinish()
        } catch is CancellationError {
            // User cancelled — do nothing
        } catch let error as ASAuthorizationError where error.code == .canceled {
            // User cancelled via system dialog
        } catch {
            errorMessage = "Apple sign-in failed. Please try again."
        }
    }

    private func handleGoogleSignIn() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let result = try await GoogleSignInHelper.signIn()
            _ = try await viewModel.auth.signInWithGoogle(
                idToken: result.idToken,
                accessToken: result.accessToken
            )
            await finalizeAndFinish()
        } catch GoogleSignInError.cancelled {
            // User cancelled — do nothing
        } catch GoogleSignInError.sdkNotConfigured {
            errorMessage = "Google sign-in is not available yet."
        } catch {
            errorMessage = "Google sign-in failed. Please try again."
        }
    }

    private func finalizeAndFinish() async {
        await viewModel.finalize()
        onFinished()
    }

    // MARK: - Subviews

    private var googleButton: some View {
        Button {
            Task { await handleGoogleSignIn() }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "g.circle.fill")
                    .font(.title3)
                Text("Continue with Google")
                    .font(Theme.Font.callout)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Theme.Color.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(Color.clear)
                    .glass(.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                            .stroke(Theme.Color.sage.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var emailButton: some View {
        Button {
            showEmailFlow = true
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "envelope.fill")
                    .font(.title3)
                Text("Continue with Email")
                    .font(Theme.Font.callout)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Theme.Color.bone)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(Theme.Color.sage)
            )
        }
        .buttonStyle(.plain)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.Color.ember)
            Text(message)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textPrimary)
        }
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Color.ember.opacity(0.1))
        )
    }
}

// MARK: - Email OTP sub-flow

private struct EmailOTPFlow: View {
    @Bindable var viewModel: OnboardingViewModel
    let onSuccess: () -> Void

    @State private var email = ""
    @State private var code = ""
    @State private var stage: EmailStage = .email
    @State private var isLoading = false
    @State private var errorMessage: String?

    private enum EmailStage { case email, code }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                switch stage {
                case .email:
                    emailEntry
                case .code:
                    codeEntry
                }
            }
            .padding(Theme.Spacing.lg)
            .navigationTitle(stage == .email ? "Enter your email" : "Check your inbox")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var emailEntry: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("We'll send a 6-digit code to verify your email.")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)

            TextField("you@example.com", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(Theme.Font.body)
                .padding(Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                        .fill(Theme.Color.bone.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                                .stroke(Theme.Color.sage.opacity(0.3), lineWidth: 1)
                        )
                )

            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.ember)
            }

            PrimaryButton("Send code", isDisabled: email.isEmpty || isLoading) {
                Task { await sendCode() }
            }

            #if DEBUG
            adminShortcuts
            #endif

            Spacer()
        }
    }

    #if DEBUG
    private var adminShortcuts: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Divider().padding(.vertical, Theme.Spacing.xs)
            Text("Debug Admin Accounts")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)

            HStack(spacing: Theme.Spacing.sm) {
                Button {
                    Task { await adminSignIn(TestCredentials.freeAdmin) }
                } label: {
                    Text("Free Admin")
                        .font(Theme.Font.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Color.forest)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                                .stroke(Theme.Color.forest.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    Task { await adminSignIn(TestCredentials.proAdmin) }
                } label: {
                    Text("Pro Admin")
                        .font(Theme.Font.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Color.amber)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                                .stroke(Theme.Color.amber.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func adminSignIn(_ cred: (email: String, password: String, tier: String)) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let profile = try await viewModel.auth.signIn(email: cred.email, password: cred.password)
            if cred.tier == "premium" && profile.subscriptionTier == .free {
                try? await viewModel.auth.updateTier(userID: profile.id, tier: .premium)
            }
            onSuccess()
        } catch {
            errorMessage = "Admin sign-in failed: \(error.localizedDescription)"
        }
    }
    #endif

    private var codeEntry: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("Enter the 6-digit code sent to **\(email)**")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)

            TextField("123456", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .font(Theme.Font.display)
                .multilineTextAlignment(.center)
                .padding(Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                        .fill(Theme.Color.bone.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                                .stroke(Theme.Color.sage.opacity(0.3), lineWidth: 1)
                        )
                )
                .frame(maxWidth: 200)

            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.ember)
            }

            PrimaryButton("Verify", isDisabled: code.count < 6 || isLoading) {
                Task { await verifyCode() }
            }

            Button("Resend code") {
                Task { await sendCode() }
            }
            .font(Theme.Font.callout)
            .foregroundStyle(Theme.Color.sage)

            Spacer()
        }
    }

    private func sendCode() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await viewModel.auth.sendMagicLink(email: email)
            stage = .code
        } catch {
            errorMessage = "Couldn't send the code. Check your connection."
        }
    }

    private func verifyCode() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await viewModel.auth.verifyEmailOTP(email: email, token: code)
            onSuccess()
        } catch {
            errorMessage = "That code didn't match. Try again or resend."
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
    AccountPage(viewModel: vm, onFinished: {})
}
