import SwiftUI
import Testing
@testable import HerbLens

@Suite("Theme palette matches brand.ts")
struct ThemeTests {
    /// Resolve a SwiftUI Color to its sRGB channels via `Color.Resolved`. Guards against
    /// hex-decoding drift from `supabase/functions/_shared/brand.ts` lines 46–51.
    private func rgb(_ color: SwiftUI.Color) -> (r: Double, g: Double, b: Double) {
        let resolved = color.resolve(in: .init())
        return (Double(resolved.red), Double(resolved.green), Double(resolved.blue))
    }

    private func approxEqual(_ a: Double, _ b: Double, tolerance: Double = 0.01) -> Bool {
        abs(a - b) < tolerance
    }

    @Test(
        "palette hex values match brand.ts",
        arguments: [
            ("sage", Theme.Color.sage, 0x7B, 0x94, 0x67),
            ("forest", Theme.Color.forest, 0x3F, 0x5E, 0x4A),
            ("bone", Theme.Color.bone, 0xF7, 0xEF, 0xE2),
            ("amber", Theme.Color.amber, 0xC9, 0x87, 0x2A),
            ("ember", Theme.Color.ember, 0xC0, 0x52, 0x2F),
            ("charcoal", Theme.Color.charcoal, 0x2A, 0x2A, 0x2A),
        ] as [(String, SwiftUI.Color, Int, Int, Int)]
    )
    func paletteHex(name: String, color: SwiftUI.Color, r: Int, g: Int, b: Int) {
        let (actualR, actualG, actualB) = rgb(color)
        #expect(approxEqual(actualR, Double(r) / 255), "\(name) red channel off")
        #expect(approxEqual(actualG, Double(g) / 255), "\(name) green channel off")
        #expect(approxEqual(actualB, Double(b) / 255), "\(name) blue channel off")
    }

    @Test("spacing scale uses 4/8/12/16/24/32")
    func spacingScale() {
        #expect(Theme.Spacing.xxs == 4)
        #expect(Theme.Spacing.xs == 8)
        #expect(Theme.Spacing.sm == 12)
        #expect(Theme.Spacing.md == 16)
        #expect(Theme.Spacing.lg == 24)
        #expect(Theme.Spacing.xl == 32)
    }

    @Test("Color hex init handles common formats")
    func colorHexFormats() {
        #expect(SwiftUI.Color(hex: "#7B9467") != nil)
        #expect(SwiftUI.Color(hex: "7B9467") != nil)
        #expect(SwiftUI.Color(hex: "#F7A") != nil)
        #expect(SwiftUI.Color(hex: "#F7EFE2FF") != nil)
        #expect(SwiftUI.Color(hex: "not-a-hex") == nil)
        #expect(SwiftUI.Color(hex: "#ZZZZZZ") == nil)
    }
}
