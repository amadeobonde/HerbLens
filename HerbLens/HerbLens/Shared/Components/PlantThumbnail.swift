import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Canonical plant image view. Prefers a bundled tea-card hero when the plant's
/// common name maps to an asset in `Recipes/*.imageset`; otherwise falls back to
/// `AsyncImage` of the remote `imageUrl` when that loads; otherwise shows a
/// tinted sage panel with the brewing mascot so the UI never renders a blank rectangle.
///
/// Feature code should use this anywhere a plant thumbnail is shown (Home
/// carousel, Vault grid, Scan result hero, HerbProfile header) so the image
/// fallback story is consistent app-wide.
public struct PlantThumbnail: View {
    public let plant: Plant
    public let cornerRadius: CGFloat

    public nonisolated init(plant: Plant, cornerRadius: CGFloat = Theme.Radius.md) {
        self.plant = plant
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        Group {
            if let local = Self.localAssetName(for: plant), hasAsset(named: local) {
                Image(local)
                    .resizable()
                    .scaledToFill()
            } else if let url = URL(string: plant.imageUrl), !plant.imageUrl.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// Warm fallback. Soft sage panel + brewing mascot — never a blank rectangle.
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Theme.Color.sage.opacity(0.12))
            .overlay(
                MascotBadge(.brewing, size: 64)
                    .opacity(0.85)
            )
    }

    private func hasAsset(named name: String) -> Bool {
        #if canImport(UIKit)
        return UIImage(named: name) != nil
        #else
        return false
        #endif
    }

    /// Map the plant's common name to a bundled asset name. Kept as a pure lookup
    /// so tests can pin expected names.
    public nonisolated static func localAssetName(for plant: Plant) -> String? {
        switch plant.commonName.lowercased() {
        case "chamomile":  return "Recipes/TeaCardChamomile"
        case "peppermint": return "Recipes/TeaCardPeppermint"
        case "ginger":     return "Recipes/TeaCardGinger"
        case "lavender":   return "Recipes/TeaCardLavender"
        case "echinacea":  return "Recipes/TeaCardEchinacea"
        default:           return nil
        }
    }
}
