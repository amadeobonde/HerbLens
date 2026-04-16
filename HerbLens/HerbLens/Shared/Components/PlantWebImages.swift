import Foundation

/// Stable Wikimedia Commons photo URLs for each seeded plant. Wikimedia thumbnails
/// are CDN-served, cacheable, don't require an API key, and are stable for years.
///
/// Pattern: `https://upload.wikimedia.org/wikipedia/commons/thumb/<partition>/<full-name>/<width>px-<full-name>`.
/// Picked lead photos from each plant's Wikipedia page so they match the common
/// name the user sees, not a stylized herbal illustration.
public enum PlantWebImages {
    private static let lookup: [String: String] = [
        // Modern photography, each URL's title verified to contain the plant
        // name so we don't ship off-topic results (earlier peppermint query
        // returned candy canes, ginger returned a street photo — swapped for
        // explicitly-tagged plant photos).
        //
        // Refresh via Openverse:
        //   curl "https://api.openverse.org/v1/images/?q=<plant>+<qualifier>&license=cc0,by,by-sa&page_size=3"
        // Use qualifier keywords ("flower", "leaves", "root", "plant") to
        // disambiguate common-noun plant names.
        "chamomile":   "https://live.staticflickr.com/305/19303821812_075e710866_b.jpg",                 // "Chamomile Flowers"
        "peppermint":  "https://live.staticflickr.com/4104/4843828911_2fccfa2ae4_b.jpg",                 // "Peppermint leaves"
        "ginger":      "https://live.staticflickr.com/4479/37310945730_8f7e9eb5b8_b.jpg",                // "Ginger root"
        "lavender":    "https://live.staticflickr.com/6121/5969843375_06402bd91e_b.jpg",                 // "Close up of lavender flower"
        "echinacea":   "https://live.staticflickr.com/6130/5959428768_8c27b9dc99_b.jpg",                 // "Echinacea Purpurea"
        "lemon balm":  "https://live.staticflickr.com/7125/7478979856_a5b6ceee4d_b.jpg",                 // "Melissa officinalis"
        "rosemary":    "https://live.staticflickr.com/3896/14562574928_77fe8f4252_b.jpg",                 // rosemary plant
        "hibiscus":    "https://live.staticflickr.com/7462/16071669752_4ed9995f7e_b.jpg",                 // "Hibiscus Flower Shot"
        "elderberry":  "https://live.staticflickr.com/8028/7636731788_046b27ee79_b.jpg",                 // "elderberry berry"
        "dandelion":   "https://live.staticflickr.com/6067/6089305754_5f64a264f4_b.jpg",                 // "Dandelion Field"
    ]

    /// Returns a stable web URL for the plant, or `nil` if we haven't curated one.
    public static func url(for commonName: String) -> URL? {
        guard let raw = lookup[commonName.lowercased()] else { return nil }
        return URL(string: raw)
    }
}
