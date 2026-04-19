import SwiftUI

struct FABButton: View {
    let isExpanded: Bool
    let action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            Image(systemName: Theme.Icon.add)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Theme.Color.bone)
                .rotationEffect(.degrees(isExpanded ? 45 : 0))
                .animation(Theme.Motion.snappy, value: isExpanded)
        }
        .frame(width: 60, height: 60)
        .background(
            LinearGradient(
                colors: [Theme.Color.sage, Theme.Color.forest],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Circle())
        .glass(.capsule)
        .shadow(Theme.Shadow.float)
        .scaleEffect(isExpanded ? 1.0 : (isPulsing ? 1.06 : 1.0))
        .accessibilityLabel(isExpanded ? "Close" : "Add")
        .accessibilityHint(isExpanded ? "Closes the plant identification panel" : "Opens plant identification options")
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    ZStack {
        Theme.Color.background.ignoresSafeArea()
        VStack(spacing: Theme.Spacing.xl) {
            FABButton(isExpanded: false, action: {})
            FABButton(isExpanded: true, action: {})
        }
    }
}
