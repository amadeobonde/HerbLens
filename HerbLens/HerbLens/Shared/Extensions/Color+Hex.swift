import SwiftUI

public extension Color {
    /// Initialize a `Color` from a hex string such as `"#7B9467"`, `"7B9467"`, `"#F7A"`, or an
    /// 8-digit `"#AARRGGBB"` / `"#RRGGBBAA"` variant. Returns `nil` when the string cannot be
    /// parsed so callers can choose a fallback rather than silently displaying a wrong color.
    nonisolated init?(hex: String) {
        var raw = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("#") { raw.removeFirst() }

        let scanner = Scanner(string: raw)
        var value: UInt64 = 0
        guard scanner.scanHexInt64(&value) else { return nil }

        let r, g, b, a: Double
        switch raw.count {
        case 3: // RGB (12-bit)
            r = Double((value >> 8) & 0xF) / 15
            g = Double((value >> 4) & 0xF) / 15
            b = Double(value & 0xF) / 15
            a = 1
        case 6: // RRGGBB
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        case 8: // RRGGBBAA
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        default:
            return nil
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
