import SwiftUI

public extension Theme {
    /// Typography tokens. Display uses `.rounded` design for a warmer, botanical feel while
    /// still riding the system SF family (supports Dynamic Type and accessibility sizes).
    nonisolated enum Font {
        public static let display: SwiftUI.Font = .system(size: 34, weight: .bold, design: .rounded)
        public static let title: SwiftUI.Font = .system(size: 28, weight: .semibold, design: .rounded)
        public static let headline: SwiftUI.Font = .system(size: 20, weight: .semibold, design: .default)
        public static let body: SwiftUI.Font = .system(size: 17, weight: .regular, design: .default)
        public static let callout: SwiftUI.Font = .system(size: 16, weight: .medium, design: .default)
        public static let caption: SwiftUI.Font = .system(size: 13, weight: .regular, design: .default)
        public static let captionMono: SwiftUI.Font = .system(size: 13, weight: .regular, design: .monospaced)
    }
}
