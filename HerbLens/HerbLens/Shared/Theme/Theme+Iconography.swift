import Foundation

public extension Theme {
    /// SF Symbol name registry. Reference these tokens (`Image(systemName: Theme.Icon.scan)`)
    /// rather than scattering symbol-string literals across feature views — that way a
    /// single change here re-skins every affordance.
    nonisolated enum Icon {
        // Navigation / tabs
        public static let scan: String = "camera.macro"
        public static let vault: String = "books.vertical.fill"
        public static let recipes: String = "leaf.fill"
        public static let home: String = "house.fill"
        public static let chat: String = "bubble.left.and.bubble.right.fill"
        public static let profile: String = "person.crop.circle"
        public static let settings: String = "gearshape.fill"
        public static let paywall: String = "sparkles"

        // FAB / identification
        public static let camera: String = "camera.fill"
        public static let barcode: String = "barcode.viewfinder"
        public static let search: String = "magnifyingglass"

        // Content actions
        public static let favorite: String = "heart.fill"
        public static let favoriteOutline: String = "heart"
        public static let timer: String = "timer"
        public static let play: String = "play.fill"
        public static let pause: String = "pause.fill"
        public static let reset: String = "arrow.counterclockwise"
        public static let next: String = "chevron.right"
        public static let previous: String = "chevron.left"
        public static let close: String = "xmark"
        public static let error: String = "exclamationmark.triangle.fill"
        public static let share: String = "square.and.arrow.up"
        public static let add: String = "plus"
        public static let more: String = "ellipsis"
    }
}
