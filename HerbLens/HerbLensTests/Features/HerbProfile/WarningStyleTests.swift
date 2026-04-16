import SwiftUI
import Testing
@testable import HerbLens

@Suite("WarningStyle severity → color mapping")
nonisolated struct WarningStyleTests {
    private func rgb(_ color: SwiftUI.Color) -> (r: Double, g: Double, b: Double) {
        let resolved = color.resolve(in: .init())
        return (Double(resolved.red), Double(resolved.green), Double(resolved.blue))
    }

    private func approxEqual(_ a: Double, _ b: Double, tolerance: Double = 0.01) -> Bool {
        abs(a - b) < tolerance
    }

    @Test(
        "severity maps to brand color",
        arguments: [
            (Severity.high, Theme.Color.ember, "High"),
            (Severity.moderate, Theme.Color.amber, "Moderate"),
            (Severity.low, Theme.Color.forest, "Low"),
        ] as [(Severity, SwiftUI.Color, String)]
    )
    func severityMapping(severity: Severity, expectedColor: SwiftUI.Color, expectedLabel: String) {
        let style = WarningStyle(severity: severity)
        let (sr, sg, sb) = rgb(style.color)
        let (er, eg, eb) = rgb(expectedColor)
        #expect(approxEqual(sr, er), "red channel off for \(severity)")
        #expect(approxEqual(sg, eg), "green channel off for \(severity)")
        #expect(approxEqual(sb, eb), "blue channel off for \(severity)")
        #expect(style.label == expectedLabel)
        #expect(style.severity == severity)
    }

    @Test("each severity gets a distinct SF Symbol")
    func distinctIcons() {
        let icons = Set(Severity.allCases.map { WarningStyle(severity: $0).iconName })
        #expect(icons.count == Severity.allCases.count)
    }
}
