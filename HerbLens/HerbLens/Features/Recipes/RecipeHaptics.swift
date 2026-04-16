#if canImport(UIKit)
import UIKit
#endif

/// Thin facade over `UIImpactFeedbackGenerator` for recipe flow haptics.
/// Accessed from the timer (non-UI code path) as well as views — needs to
/// be reachable from any isolation context.
nonisolated enum RecipeHaptics {
    static func start() {
#if canImport(UIKit)
        Task { @MainActor in
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        }
#endif
    }

    static func tick() {
#if canImport(UIKit)
        Task { @MainActor in
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }
#endif
    }

    static func finish() {
#if canImport(UIKit)
        Task { @MainActor in
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
#endif
    }
}
