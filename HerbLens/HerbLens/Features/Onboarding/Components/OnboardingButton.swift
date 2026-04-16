import SwiftUI

struct OnboardingPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Theme.Color.bone)
                } else {
                    Text(title)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Color.bone)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.Color.sage.opacity(isEnabled ? 1.0 : 0.45))
            )
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(.plain)
    }
}

struct OnboardingSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Font.callout)
                .foregroundStyle(Theme.Color.forest)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .buttonStyle(.plain)
    }
}
