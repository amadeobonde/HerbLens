import Foundation

/// Stable Wikimedia Commons photo URLs for each seeded plant. Wikimedia thumbnails
/// are CDN-served, cacheable, don't require an API key, and are stable for years.
///
/// Pattern: `https://upload.wikimedia.org/wikipedia/commons/thumb/<partition>/<full-name>/<width>px-<full-name>`.
/// Picked lead photos from each plant's Wikipedia page so they match the common
/// name the user sees, not a stylized herbal illustration.
public enum PlantWebImages {
    private static let lookup: [String: String] = [
        // (keys are the plant's `commonName.lowercased()`)
        // URLs verified as of 2026-04-16 via Wikipedia REST API `originalimage.source`.
        // If Wikimedia renames files, refresh by hitting
        // `https://en.wikipedia.org/api/rest_v1/page/summary/<Title>` and taking
        // the `originalimage.source` field.
        "chamomile":   "https://upload.wikimedia.org/wikipedia/commons/2/26/Kamomillasaunio_%28Matricaria_recutita%29.JPG",
        "peppermint":  "https://upload.wikimedia.org/wikipedia/commons/7/72/Pfefferminze_natur_peppermint.jpg",
        "ginger":      "https://upload.wikimedia.org/wikipedia/commons/1/18/Koeh-146-no_text.jpg",
        "lavender":    "https://upload.wikimedia.org/wikipedia/commons/7/7e/Single_lavender_flower02.jpg",
        "echinacea":   "https://upload.wikimedia.org/wikipedia/commons/8/8e/Echinacea_purpurea_Grandview_Prairie.jpg",
        "lemon balm":  "https://upload.wikimedia.org/wikipedia/commons/7/70/Lemon_balm_plant.jpg",
        "rosemary":    "https://upload.wikimedia.org/wikipedia/commons/a/a3/Rosemary_in_bloom.JPG",
        "hibiscus":    "https://upload.wikimedia.org/wikipedia/commons/c/cb/Hibiscus_flower_TZ.jpg",
        "elderberry":  "https://upload.wikimedia.org/wikipedia/commons/6/61/Sambucus_nigra_004.jpg",
        "dandelion":   "https://upload.wikimedia.org/wikipedia/commons/b/b2/Taraxacum_officinale_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-135.jpg",
    ]

    /// Returns a stable web URL for the plant, or `nil` if we haven't curated one.
    public static func url(for commonName: String) -> URL? {
        guard let raw = lookup[commonName.lowercased()] else { return nil }
        return URL(string: raw)
    }
}
