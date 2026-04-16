import SwiftUI

/// Root Settings screen. Binds to `SettingsViewModel`, stitches together the five
/// sections (Profile · Health · Subscription · Legal · Account), and presents the
/// paywall sheet when the free user taps "Upgrade to Pro".
struct SettingsView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel = SettingsViewModel()
    @State private var showPaywall: Bool = false

    /// Optional cached profile — on warm navigations the tab container can pass the
    /// already-fetched `UserProfile` so we don't round-trip the auth service. Previews
    /// also lean on this.
    let initialProfile: UserProfile?

    init(initialProfile: UserProfile? = nil) {
        self.initialProfile = initialProfile
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    SettingsProfileSection(
                        profile: viewModel.profile,
                        tier: viewModel.tier,
                        onSignOut: {
                            Task { await viewModel.signOut(auth: dependencies.auth) }
                        }
                    )

                    SettingsHealthSection(
                        draft: $viewModel.healthDraft,
                        isDirty: viewModel.isHealthDirty,
                        isSaving: viewModel.isSavingHealth,
                        onSave: {
                            Task {
                                await viewModel.saveHealthProfile(using: dependencies.healthProfile)
                            }
                        }
                    )

                    SettingsSubscriptionSection(
                        tier: viewModel.tier,
                        summary: viewModel.subscriptionSummary,
                        isRestoring: false,
                        onUpgrade: { showPaywall = true },
                        onRestore: {
                            Task {
                                _ = try? await dependencies.subscriptions.restore()
                                await viewModel.refreshTier(subscriptions: dependencies.subscriptions)
                            }
                        }
                    )

                    SettingsLegalSection()

                    SettingsAccountSection(
                        onDeleteAccount: {
                            // TODO(coordination): pipe through `AuthService.deleteAccount`
                            // once Instance 1/2 add it to the protocol. For now we sign
                            // the user out so the destructive intent is at least visible.
                            Task { await viewModel.signOut(auth: dependencies.auth) }
                        }
                    )

                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Color.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationDestination(for: LegalDocumentKind.self) { kind in
                LegalDocumentView(kind: kind)
            }
            .task {
                await viewModel.load(
                    auth: dependencies.auth,
                    healthRepo: dependencies.healthProfile,
                    subscriptions: dependencies.subscriptions,
                    cachedProfile: initialProfile
                )
            }
            .sheet(isPresented: $showPaywall, onDismiss: {
                Task { await viewModel.refreshTier(subscriptions: dependencies.subscriptions) }
            }) {
                PaywallView()
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(Theme.Font.caption)
            .foregroundStyle(Theme.Color.ember)
            .padding(Theme.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous)
                    .fill(Theme.Color.ember.opacity(0.1))
            )
    }
}

#Preview("Settings — free tier") {
    SettingsView(initialProfile: SampleData.userProfile)
        .environment(\.dependencies, .mock)
}
