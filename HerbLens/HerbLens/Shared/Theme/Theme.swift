import SwiftUI

/// Design-token namespace for HerbLens. All app surfaces read palette, typography, spacing,
/// and glass tokens through this type rather than using raw SwiftUI values. Keeps the
/// brand system centralized — updating a single constant here propagates everywhere.
public nonisolated enum Theme {}
