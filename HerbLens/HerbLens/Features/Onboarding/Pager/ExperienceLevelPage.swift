import SwiftUI

struct ExperienceLevelPage: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: @Sendable () -> Void

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    MascotBadge(.teacher, size: 120)
                        .padding(.top, Theme.Spacing.xl)

                    VStack(spacing: Theme.Spacing.xs) {
                        Text("How herb-savvy are you?")
                            .font(Theme.Font.title)
                            .foregroundStyle(Theme.Color.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("We'll tailor the depth of explanations to your level.")
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.lg)
                    }

                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(ExperienceLevel.allCases, id: \.self) { level in
                            ExperienceCard(
                                level: level,
                                isSelected: viewModel.draftExperience == level
                            ) {
                                withAnimation(Theme.Motion.snappy) {
                                    viewModel.draftExperience = level
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    Spacer(minLength: 120)
                }
            }
            .scrollIndicators(.hidden)

            VStack {
                Spacer()
                PrimaryButton("Continue", action: onContinue)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, 64)
            }
        }
    }
}

private struct ExperienceCard: View {
    let level: ExperienceLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.md) {
                MascotBadge(mascot, size: 56, breathes: false)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Color.textPrimary)

                    Text(subtitle)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.Color.sage)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(Theme.Spacing.md)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .fill(Theme.Color.sage.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                .stroke(Theme.Color.sage, lineWidth: 1.5)
                        )
                } else {
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .fill(Color.clear)
                        .glass(.card)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(Theme.Motion.snappy, value: isSelected)
    }

    private var mascot: MascotBadge.Variant {
        switch level {
        case .beginner: .default
        case .intermediate: .teacher
        case .advanced: .brewing
        }
    }

    private var title: String {
        switch level {
        case .beginner: "Just getting started"
        case .intermediate: "I know my herbs"
        case .advanced: "Herbalist in training"
        }
    }

    private var subtitle: String {
        switch level {
        case .beginner: "Show me everything — plain language, tips, and guidance."
        case .intermediate: "I know the basics. Give me the details that matter."
        case .advanced: "Skip the intro — I want the deep science."
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
    ExperienceLevelPage(viewModel: vm, onContinue: {})
}
