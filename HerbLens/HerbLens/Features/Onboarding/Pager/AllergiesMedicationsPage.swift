import SwiftUI

/// Page 3 of the pager. Two glass cards collect comma-separated free text for
/// allergies and medications respectively. Skip lives top-right; Continue at
/// the bottom commits the parsed lists to the view model and advances.
struct AllergiesMedicationsPage: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var allergiesText: String = ""
    @State private var medicationsText: String = ""

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.Color.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Spec asks for `MascotBadge(.thinking)` with `.teacher` fallback.
                    // The asset catalog ships only the six listed variants today, so
                    // we use `.teacher` directly and leave a TODO for asset gen.
                    MascotBadge(.teacher, size: 130)
                        .padding(.top, Theme.Spacing.xl)

                    VStack(spacing: Theme.Spacing.xs) {
                        Text("Anything we should watch for?")
                            .font(Theme.Font.title)
                            .foregroundStyle(Theme.Color.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("List allergies and medications so we can flag risky combinations. Separate items with commas.")
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.lg)
                    }

                    VStack(spacing: Theme.Spacing.md) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Label("Allergies", systemImage: "allergens")
                                    .font(Theme.Font.headline)
                                    .foregroundStyle(Theme.Color.textPrimary)

                                CommaSeparatedField(
                                    placeholder: "ragweed, tree nuts, latex",
                                    text: $allergiesText,
                                    onChange: commitAllergies
                                )
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Label("Medications", systemImage: "pills")
                                    .font(Theme.Font.headline)
                                    .foregroundStyle(Theme.Color.textPrimary)

                                CommaSeparatedField(
                                    placeholder: "warfarin, lisinopril",
                                    text: $medicationsText,
                                    onChange: commitMedications
                                )
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    Spacer(minLength: 140)
                }
            }
            .scrollIndicators(.hidden)

            VStack {
                Spacer()
                PrimaryButton("Continue", action: {
                    commitAllergies()
                    commitMedications()
                    onContinue()
                })
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, 64) // clear progress dots
            }

            Button(action: {
                onSkip()
            }) {
                Text("Skip")
                    .font(Theme.Font.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Color.forest)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.xs)
            }
            .buttonStyle(.plain)
            .glass(.capsule)
            .clipShape(Capsule())
            .padding(.top, Theme.Spacing.lg)
            .padding(.trailing, Theme.Spacing.lg)
        }
        .onAppear {
            // Pre-fill from any existing draft state so navigating back doesn't
            // reset the user's entries.
            if allergiesText.isEmpty {
                allergiesText = viewModel.draftAllergies.joined(separator: ", ")
            }
            if medicationsText.isEmpty {
                medicationsText = viewModel.draftMedications.joined(separator: ", ")
            }
        }
    }

    private func commitAllergies() {
        viewModel.draftAllergies = parse(allergiesText)
    }

    private func commitMedications() {
        viewModel.draftMedications = parse(medicationsText)
    }

    private func parse(_ raw: String) -> [String] {
        raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private struct CommaSeparatedField: View {
    let placeholder: String
    @Binding var text: String
    var onChange: () -> Void = {}

    @FocusState private var focused: Bool

    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .lineLimit(2...4)
            .font(Theme.Font.body)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focused)
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .fill(Theme.Color.bone.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                            .stroke(Theme.Color.sage.opacity(focused ? 0.8 : 0.3), lineWidth: 1)
                    )
            )
            .onChange(of: text) { _, _ in onChange() }
    }
}

#Preview {
    let mock = AppDependencies.mock
    let vm = OnboardingViewModel(
        auth: mock.auth,
        healthProfileRepo: mock.healthProfile,
        subscriptions: mock.subscriptions
    )
    AllergiesMedicationsPage(viewModel: vm, onContinue: {}, onSkip: {})
}
