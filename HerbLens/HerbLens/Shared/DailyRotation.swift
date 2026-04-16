import Foundation

/// Day-of-year based deterministic rotation. Used by the Home "Featured today"
/// carousel so users see a different set of plants every day without any server
/// round-trip. Rotation is stable per calendar day (UTC) — two taps same day
/// produce the same list.
public enum DailyRotation {
    /// Returns `count` items sliced from `pool` starting at today's offset. Wraps
    /// around if `count` > `pool.count`.
    public static func pick<T>(_ count: Int, from pool: [T], date: Date = Date()) -> [T] {
        guard !pool.isEmpty else { return [] }
        let take = min(count, pool.count)
        let offset = dayOfYear(date) % pool.count
        var out: [T] = []
        out.reserveCapacity(take)
        for i in 0..<take {
            out.append(pool[(offset + i) % pool.count])
        }
        return out
    }

    /// Returns the full pool rotated so today's offset sits at index 0. Handy for
    /// carousels that want to show *all* items but reorder each day.
    public static func rotated<T>(_ pool: [T], date: Date = Date()) -> [T] {
        guard !pool.isEmpty else { return [] }
        let offset = dayOfYear(date) % pool.count
        return Array(pool[offset...] + pool[..<offset])
    }

    private static func dayOfYear(_ date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        return cal.ordinality(of: .day, in: .year, for: date) ?? 0
    }
}
