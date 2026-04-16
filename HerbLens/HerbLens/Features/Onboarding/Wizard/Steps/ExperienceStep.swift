import SwiftUI

struct ExperienceStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        WizardChrome(
            viewModel: viewModel,
            step: .experience,
            canSkip: false
        ) {
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                    let isSelected = viewModel.draftExperience == level
                    Button {
                        viewModel.draftExperience = level
                    } label: {
                        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(isSelected ? Theme.Color.sage : Theme.Color.forest.opacity(0.4))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.title)
                                    .font(Theme.Font.headline)
                                    .foregroundStyle(Theme.Color.textPrimary)
                                Text(level.subtitle)
                                    .font(Theme.Font.caption)
                                    .foregroundStyle(Theme.Color.textSecondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                        .padding(Theme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? Theme.Color.sage.opacity(0.12) : Theme.Color.bone)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(isSelected ? Theme.Color.sage : Theme.Color.sage.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private extension ExperienceLevel {
    var title: String {
        switch self {
        case .beginner: "Just starting out"
        case .intermediate: "Some experience"
        case .advanced: "I know my herbs"
        }
    }

    var subtitle: String {
        switch self {
        case .beginner: "Keep it simple — plain-language explanations and basic brews."
        case .intermediate: "I brew occasionally and know common herbs."
        case .advanced: "Give me full detail, contraindications, and tincture recipes."
        }
    }
}
