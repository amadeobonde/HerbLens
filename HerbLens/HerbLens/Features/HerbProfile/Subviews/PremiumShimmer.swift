import SwiftUI

/// Animated gradient mask applied on top of a view. Used to distinguish the premium
/// tier's health-score ring from the free-tier static version.
struct PremiumShimmer: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.overlay(shimmerOverlay.allowsHitTesting(false).blendMode(.plusLighter))
        } else {
            content
        }
    }

    private var shimmerOverlay: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let phase = (sin(t * 1.1) + 1) / 2  // 0...1 gentle wave
            LinearGradient(
                stops: [
                    .init(color: .clear, location: max(0, phase - 0.25)),
                    .init(color: .white.opacity(0.35), location: phase),
                    .init(color: .clear, location: min(1, phase + 0.25)),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

extension View {
    /// Apply the premium shimmer treatment. Becomes a no-op for free-tier users.
    func premiumShimmer(enabled: Bool) -> some View {
        modifier(PremiumShimmer(enabled: enabled))
    }
}
