import CoreGraphics

public extension Theme {
    /// Corner-radius scale: 8 / 12 / 16 / 20, plus a `pill` token (sentinel large value
    /// suitable for capsule/pill shapes). Use named tokens rather than magic numbers so
    /// surface families stay coherent.
    nonisolated enum Radius {
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 20
        /// Effectively infinite — pair with a fixed-height container to produce a true pill.
        public static let pill: CGFloat = 999
    }
}
