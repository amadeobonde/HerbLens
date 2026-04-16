import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// A one-method haptic protocol. The thread view model calls `tick()` on first streamed
/// token. Tests inject a spy to assert the haptic fires exactly once per reply.
protocol HapticTicking: Sendable {
    func tick()
}

/// Production adapter over `UIImpactFeedbackGenerator`. Generator lifetime is short-lived
/// on purpose — the `.light` style does not benefit from pre-preparation at this cadence.
struct LiveHapticTicking: HapticTicking {
    func tick() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
