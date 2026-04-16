import SwiftUI

public extension Theme {
    /// Named roles for Liquid Glass surfaces. Deployment target is iOS 26, so the native
    /// `.glassEffect(_:in:)` modifier is always available — feature views should apply
    /// these roles via the `.glass(_:)` view helper below rather than constructing the
    /// modifier ad-hoc.
    nonisolated enum Glass {
        public nonisolated enum Role: Sendable, Hashable {
            /// Navigation-bar / top-chrome surface — regular prominence, sharp rect.
            case navBar
            /// Card / tile — regular prominence, rounded rect with default radius.
            case card
            /// Floating capsule (pills, filter chips) — regular prominence, capsule.
            case capsule
            /// Modal sheet chrome — prominent so content behind fades back.
            case modal
            /// Subtle background wash for grouped content — thin regular.
            case subtle
        }
    }
}

public extension View {
    /// Apply a Theme-defined Liquid Glass surface to this view.
    @ViewBuilder
    func glass(_ role: Theme.Glass.Role) -> some View {
        switch role {
        case .navBar:
            self.glassEffect(.regular, in: .rect)
        case .card:
            self.glassEffect(.regular, in: .rect(cornerRadius: 16))
        case .capsule:
            self.glassEffect(.regular, in: .capsule)
        case .modal:
            self.glassEffect(.regular, in: .rect(cornerRadius: 24))
        case .subtle:
            self.glassEffect(.regular, in: .rect(cornerRadius: 12))
        }
    }
}
