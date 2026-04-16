import SwiftUI

/// The Bamboo mascot in a circular frame with a subtle breathing-scale idle animation
/// (scale 1.00 → 1.04 over 2s in, 2s out — 4s full cycle).
struct BambooAvatarView: View {
    var size: CGFloat = 36
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Image("BambooAvatar")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Theme.Color.sage.opacity(0.25), lineWidth: 1))
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    scale = 1.04
                }
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    BambooAvatarView(size: 120)
        .padding(Theme.Spacing.lg)
        .background(Theme.Color.background)
}
