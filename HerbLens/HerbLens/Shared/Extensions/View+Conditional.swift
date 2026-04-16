import SwiftUI

public extension View {
    /// Apply a view transformation only when `condition` is `true`.
    ///
    ///     view.applyIf(isActive) { $0.bold() }
    ///
    /// Prefer this over inline branching when the transform is simple. For complex
    /// conditional trees, prefer a wrapping parent view so the type identity stays stable.
    @ViewBuilder
    func applyIf<Transformed: View>(
        _ condition: Bool,
        transform: (Self) -> Transformed
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
