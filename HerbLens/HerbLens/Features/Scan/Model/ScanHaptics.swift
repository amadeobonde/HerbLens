import UIKit

/// Haptic patterns tuned to the success animation in `ScanResultView`. Free tier gets a
/// single medium impact; premium gets a richer multi-pulse to reinforce the glow.
@MainActor
public enum ScanHaptics {
    public static func success(tier: SubscriptionTier) {
        switch tier {
        case .free:
            let gen = UIImpactFeedbackGenerator(style: .medium)
            gen.prepare()
            gen.impactOccurred()
        case .premium:
            let notify = UINotificationFeedbackGenerator()
            notify.prepare()
            notify.notificationOccurred(.success)
            schedulePulse(style: .soft, delay: .milliseconds(80))
            schedulePulse(style: .rigid, delay: .milliseconds(160))
        }
    }

    public static func shutter() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        gen.impactOccurred()
    }

    private static func schedulePulse(style: UIImpactFeedbackGenerator.FeedbackStyle, delay: DispatchTimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let gen = UIImpactFeedbackGenerator(style: style)
            gen.prepare()
            gen.impactOccurred()
        }
    }
}
