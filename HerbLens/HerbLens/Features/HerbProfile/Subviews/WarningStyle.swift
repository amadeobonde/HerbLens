import SwiftUI

/// Pure mapping of `Severity` → (accent color, icon, label). Keeps the warning-row view
/// and the contraindications-tab view consistent with a single test target.
public nonisolated struct WarningStyle: Sendable, Hashable {
    public let severity: Severity
    public let color: SwiftUI.Color
    public let iconName: String
    public let label: String

    public init(severity: Severity) {
        self.severity = severity
        switch severity {
        case .high:
            self.color = Theme.Color.ember
            self.iconName = "exclamationmark.octagon.fill"
            self.label = "High"
        case .moderate:
            self.color = Theme.Color.amber
            self.iconName = "exclamationmark.triangle.fill"
            self.label = "Moderate"
        case .low:
            self.color = Theme.Color.forest
            self.iconName = "info.circle.fill"
            self.label = "Low"
        }
    }
}
