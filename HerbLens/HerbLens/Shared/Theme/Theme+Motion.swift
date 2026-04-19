import SwiftUI

public extension Theme {
    /// Motion curves for HerbLens. Three named springs cover ~95% of in-app animations:
    /// `snappy` for taps and immediate UI feedback, `bounce` for celebratory moments
    /// (mascot pop-in, success), and `gentle` for ambient transitions (cards rearranging,
    /// background fades). Reach for these tokens rather than hand-tuning a spring per view.
    nonisolated enum Motion {
        public static let snappy: Animation = .interpolatingSpring(stiffness: 380, damping: 28)
        public static let bounce: Animation = .interpolatingSpring(stiffness: 220, damping: 14)
        public static let gentle: Animation = .interpolatingSpring(stiffness: 140, damping: 20)
        public static let fidget: Animation = .interpolatingSpring(stiffness: 300, damping: 18)
        public static let celebrate: Animation = .interpolatingSpring(stiffness: 260, damping: 10)
        public static let micro: Animation = .interpolatingSpring(stiffness: 500, damping: 35)
    }
}
