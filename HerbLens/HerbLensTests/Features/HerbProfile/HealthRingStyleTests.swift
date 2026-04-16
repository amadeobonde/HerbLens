import SwiftUI
import Testing
@testable import HerbLens

@Suite("HealthRingStyle presentation rules")
nonisolated struct HealthRingStyleTests {
    private func rgb(_ color: SwiftUI.Color) -> (r: Double, g: Double, b: Double) {
        let resolved = color.resolve(in: .init())
        return (Double(resolved.red), Double(resolved.green), Double(resolved.blue))
    }

    private func approxEqual(_ a: Double, _ b: Double, tolerance: Double = 0.01) -> Bool {
        abs(a - b) < tolerance
    }

    @Test(
        "trim fraction respects 0/50/100 boundaries",
        arguments: [
            (0, 0.0),
            (25, 0.25),
            (50, 0.5),
            (75, 0.75),
            (100, 1.0),
        ] as [(Int, Double)]
    )
    func trimBoundaries(score: Int, expectedFraction: Double) {
        let style = HealthRingStyle(score: score)
        #expect(style.trimFraction == expectedFraction)
        #expect(style.score == score)
    }

    @Test("clamps out-of-range scores")
    func clampsOutOfRange() {
        let negative = HealthRingStyle(score: -10)
        #expect(negative.score == 0)
        #expect(negative.trimFraction == 0.0)

        let tooHigh = HealthRingStyle(score: 150)
        #expect(tooHigh.score == 100)
        #expect(tooHigh.trimFraction == 1.0)
    }

    @Test(
        "color ramp ember/amber/sage",
        arguments: [
            (0, Theme.Color.ember, "low match"),
            (39, Theme.Color.ember, "low match"),
            (40, Theme.Color.amber, "moderate match"),
            (69, Theme.Color.amber, "moderate match"),
            (70, Theme.Color.sage, "strong match"),
            (92, Theme.Color.sage, "strong match"),
            (100, Theme.Color.sage, "strong match"),
        ] as [(Int, SwiftUI.Color, String)]
    )
    func colorAndLabel(score: Int, expectedColor: SwiftUI.Color, expectedLabel: String) {
        let style = HealthRingStyle(score: score)
        let (sr, sg, sb) = rgb(style.color)
        let (er, eg, eb) = rgb(expectedColor)
        #expect(approxEqual(sr, er), "red channel off at score \(score)")
        #expect(approxEqual(sg, eg), "green channel off at score \(score)")
        #expect(approxEqual(sb, eb), "blue channel off at score \(score)")
        #expect(style.label == expectedLabel)
    }
}
