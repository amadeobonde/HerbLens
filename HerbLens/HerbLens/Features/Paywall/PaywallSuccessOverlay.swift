import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Full-screen celebration overlay that appears once a purchase or restore succeeds.
/// Scale-in + fade of the celebrating Bamboo mascot, success haptic, auto-dismiss after
/// a short hold so the user gets a beat of delight before returning to the app.
struct PaywallSuccessOverlay: View {
    let onComplete: () -> Void

    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            Theme.Color.bone
                .ignoresSafeArea()
                .opacity(opacity * 0.92)

            VStack(spacing: Theme.Spacing.md) {
                MascotBadge(.celebrating, size: 220)
                    .scaleEffect(scale)
                    .opacity(opacity)

                VStack(spacing: Theme.Spacing.xxs) {
                    Text("Welcome to Pro")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("Your full apothecary just unlocked.")
                        .font(Theme.Font.callout)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            triggerHaptic()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            Task {
                try? await Task.sleep(for: .seconds(1.8))
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0.0
                }
                try? await Task.sleep(for: .milliseconds(350))
                onComplete()
            }
        }
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }
}
