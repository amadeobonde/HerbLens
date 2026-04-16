import SwiftUI

public extension Theme {
    /// Drop-shadow tokens. Three elevations:
    /// - `card` — resting tile/card lift off the bone background.
    /// - `float` — buttons or chips lifted above content.
    /// - `modal` — bottom-sheet and modal chrome separation from underlying surface.
    nonisolated enum Shadow {
        public nonisolated struct Style: Sendable, Hashable {
            public let color: SwiftUI.Color
            public let radius: CGFloat
            public let x: CGFloat
            public let y: CGFloat

            public nonisolated init(color: SwiftUI.Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
                self.color = color
                self.radius = radius
                self.x = x
                self.y = y
            }
        }

        public static let card: Style = Style(
            color: SwiftUI.Color.black.opacity(0.08),
            radius: 12,
            x: 0,
            y: 4
        )

        public static let float: Style = Style(
            color: SwiftUI.Color.black.opacity(0.14),
            radius: 18,
            x: 0,
            y: 8
        )

        public static let modal: Style = Style(
            color: SwiftUI.Color.black.opacity(0.22),
            radius: 28,
            x: 0,
            y: 12
        )
    }
}

public extension View {
    /// Apply a Theme-defined drop shadow style to this view.
    func shadow(_ style: Theme.Shadow.Style) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
