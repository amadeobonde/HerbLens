import SwiftUI

public extension Theme {
    /// Raw palette — hex values are the source of truth in
    /// `supabase/functions/_shared/brand.ts`. Keep these in lock-step.
    nonisolated enum Color {
        public static let sage: SwiftUI.Color = SwiftUI.Color(hex: "#7B9467")!
        public static let forest: SwiftUI.Color = SwiftUI.Color(hex: "#3F5E4A")!
        public static let bone: SwiftUI.Color = SwiftUI.Color(hex: "#F7EFE2")!
        public static let amber: SwiftUI.Color = SwiftUI.Color(hex: "#C9872A")!
        public static let ember: SwiftUI.Color = SwiftUI.Color(hex: "#C0522F")!
        public static let charcoal: SwiftUI.Color = SwiftUI.Color(hex: "#2A2A2A")!

        // Semantic tokens — reference these from feature views rather than raw palette.
        public static let background: SwiftUI.Color = bone
        public static let surface: SwiftUI.Color = bone
        public static let primary: SwiftUI.Color = sage
        public static let accent: SwiftUI.Color = amber
        public static let textPrimary: SwiftUI.Color = charcoal
        public static let textSecondary: SwiftUI.Color = forest
        public static let warning: SwiftUI.Color = amber
        public static let destructive: SwiftUI.Color = ember
    }
}
