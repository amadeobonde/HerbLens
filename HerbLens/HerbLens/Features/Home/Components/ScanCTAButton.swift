import SwiftUI
import UIKit

/// The big "Scan" call-to-action at the top of the home feed. Bamboo peeks from the
/// upper-right edge, partially escaping the rounded rectangle. `.allowsHitTesting(false)`
/// on the mascot so the entire button stays tappable; no `.clipped()` so the head can
/// poke above the top edge.
struct ScanCTAButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            buttonContent
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scan a plant")
        .accessibilityHint("Opens the camera to identify a plant")
    }

    private var buttonContent: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.Color.sage, Theme.Color.forest],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 132)
                .shadow(Theme.Shadow.float)

            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Theme.Color.bone.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: Theme.Icon.scan)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Theme.Color.bone)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan a plant")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.bone)
                    Text("Identify · score · brew")
                        .font(Theme.Font.callout)
                        .foregroundStyle(Theme.Color.bone.opacity(0.85))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 132)

            mascotImage
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .offset(x: 12, y: -36)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
    }

    /// Returns the canonical Bamboo asset if Instance 1 has published the imageset,
    /// otherwise a soft sage SF Symbol so the CTA still ships during parallel work.
    private var mascotImage: Image {
        if UIImage(named: "BambooCanonical") != nil {
            return Image("BambooCanonical")
        }
        return Image(systemName: "leaf.circle.fill")
    }
}
