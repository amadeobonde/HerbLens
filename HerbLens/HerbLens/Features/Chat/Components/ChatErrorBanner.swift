import SwiftUI

/// Amber banner shown above the input when a stream fails. Dismissed by the user; the
/// thread view model resets its `errorBanner` state via `dismissError()`.
struct ChatErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.Color.ember)
            Text(message)
                .font(Theme.Font.callout)
                .foregroundStyle(Theme.Color.charcoal)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundStyle(Theme.Color.charcoal)
            }
            .accessibilityLabel("Dismiss error")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Color.amber.opacity(0.22))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Color.amber.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
