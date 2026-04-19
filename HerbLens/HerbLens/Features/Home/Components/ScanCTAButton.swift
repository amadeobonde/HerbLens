import SwiftUI

struct ScanCTAButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Theme.Color.bone.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: Theme.Icon.scan)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.Color.bone)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Scan a plant")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Color.bone)
                    Text("Identify · score · brew")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.bone.opacity(0.8))
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Color.bone.opacity(0.6))
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                LinearGradient(
                    colors: [Theme.Color.sage, Theme.Color.forest],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
            )
            .shadow(Theme.Shadow.float)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scan a plant")
        .accessibilityHint("Opens the camera to identify a plant")
    }
}
