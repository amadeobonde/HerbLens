import Foundation

/// Stable Wikimedia Commons photo URLs for each seeded plant. Wikimedia thumbnails
/// are CDN-served, cacheable, don't require an API key, and are stable for years.
///
/// Pattern: `https://upload.wikimedia.org/wikipedia/commons/thumb/<partition>/<full-name>/<width>px-<full-name>`.
/// Picked lead photos from each plant's Wikipedia page so they match the common
/// name the user sees, not a stylized herbal illustration.
public enum PlantWebImages {
    private static let lookup: [String: String] = [
        // Visually verified Wikipedia Commons photos. Every URL was downloaded
        // and inspected by a human (or Claude with image-read access) to confirm
        // the photo actually depicts the named plant — not a tagged-but-wrong
        // candy/shrimp/rabbit. Wikipedia infobox images are community-curated so
        // they're more reliable than search-API first-results.
        //
        // To refresh: pull the originalimage.source from
        //   https://en.wikipedia.org/api/rest_v1/page/summary/<scientific_name>
        // then download + visually verify before swapping the URL in.
        "chamomile":   "https://upload.wikimedia.org/wikipedia/commons/c/c8/Matricaria_February_2008-1.jpg",
        "peppermint":  "https://upload.wikimedia.org/wikipedia/commons/7/72/Pfefferminze_natur_peppermint.jpg",
        "ginger":      "https://upload.wikimedia.org/wikipedia/commons/thumb/b/ba/Berlin-Dahlem%2C_botanischer_Garten%2C_Zingiber_officinale.JPG/960px-Berlin-Dahlem%2C_botanischer_Garten%2C_Zingiber_officinale.JPG",
        "lavender":    "https://upload.wikimedia.org/wikipedia/commons/7/7e/Single_lavender_flower02.jpg",
        "echinacea":   "https://upload.wikimedia.org/wikipedia/commons/8/8e/Echinacea_purpurea_Grandview_Prairie.jpg",
        "lemon balm":  "https://upload.wikimedia.org/wikipedia/commons/7/70/Lemon_balm_plant.jpg",
        "rosemary":    "https://upload.wikimedia.org/wikipedia/commons/a/a3/Rosemary_in_bloom.JPG",
        "hibiscus":    "https://upload.wikimedia.org/wikipedia/commons/c/cb/Hibiscus_flower_TZ.jpg",
        "elderberry":  "https://upload.wikimedia.org/wikipedia/commons/6/61/Sambucus_nigra_004.jpg",
        "dandelion":   "https://upload.wikimedia.org/wikipedia/commons/4/4f/DandelionFlower.jpg",
    ]

    /// Returns a stable web URL for the plant, or `nil` if we haven't curated one.
    public static func url(for commonName: String) -> URL? {
        guard let raw = lookup[commonName.lowercased()] else { return nil }
        return URL(string: raw)
    }
}
