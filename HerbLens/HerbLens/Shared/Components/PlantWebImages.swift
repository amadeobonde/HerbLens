import Foundation

/// Stable Wikimedia Commons photo URLs for each seeded plant. Wikimedia thumbnails
/// are CDN-served, cacheable, don't require an API key, and are stable for years.
///
/// Pattern: `https://upload.wikimedia.org/wikipedia/commons/thumb/<partition>/<full-name>/<width>px-<full-name>`.
/// Picked lead photos from each plant's Wikipedia page so they match the common
/// name the user sees, not a stylized herbal illustration.
public enum PlantWebImages {
    private static let lookup: [String: String] = [
        // Modern photography sourced via Openverse (aggregates Unsplash + Flickr
        // + Commons Featured Pictures). Each URL is CC-licensed and served by a
        // stable CDN (`live.staticflickr.com` for Flickr, upload.wikimedia.org for
        // Commons). Refresh by hitting:
        // `https://api.openverse.org/v1/images/?q=<plant>&license=cc0,by,by-sa&page_size=1`
        // and replacing the URL — no API key required.
        "chamomile":   "https://live.staticflickr.com/3827/9003193090_01b6c86e3a_b.jpg",
        "peppermint":  "https://live.staticflickr.com/8154/7777976014_b73ef12597_b.jpg",
        "ginger":      "https://live.staticflickr.com/3331/3478499255_5c633c76ae_b.jpg",
        "lavender":    "https://live.staticflickr.com/1340/562028359_a104d7c3fc.jpg",
        "echinacea":   "https://live.staticflickr.com/4506/37344056570_e4f6d353f0_b.jpg",
        "lemon balm":  "https://upload.wikimedia.org/wikipedia/commons/3/36/Melissa_officinalis_Bee_Balm%2CLemon_Balm_%E1%83%91%E1%83%90%E1%83%A0%E1%83%90%E1%83%9B%E1%83%91%E1%83%9D.JPG",
        "rosemary":    "https://live.staticflickr.com/3896/14562574928_77fe8f4252_b.jpg",
        "hibiscus":    "https://live.staticflickr.com/8697/17175399565_4442910900_b.jpg",
        "elderberry":  "https://live.staticflickr.com/6093/6222073617_4b1bac0800_b.jpg",
        "dandelion":   "https://live.staticflickr.com/68/177851662_b2622b4238_b.jpg",
    ]

    /// Returns a stable web URL for the plant, or `nil` if we haven't curated one.
    public static func url(for commonName: String) -> URL? {
        guard let raw = lookup[commonName.lowercased()] else { return nil }
        return URL(string: raw)
    }
}
