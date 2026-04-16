import SwiftUI

/// Recents row: horizontal scroll of recently-scanned plants. Resolves each
/// `Scan.identifiedPlantId` against the preloaded `recentPlantsByID` map. Hides
/// itself when there's nothing to show — keeps the home feed clean for new users.
struct RecentlyScannedRow: View {
    let recents: [Scan]
    let plantsByID: [String: Plant]
    let onSelect: (Plant) -> Void

    private var resolved: [(scan: Scan, plant: Plant)] {
        recents.compactMap { scan in
            plantsByID[scan.identifiedPlantId].map { (scan, $0) }
        }
    }

    var body: some View {
        if !resolved.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Recently scanned")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .padding(.horizontal, Theme.Spacing.md)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.md) {
                        ForEach(resolved, id: \.scan.id) { entry in
                            Button {
                                onSelect(entry.plant)
                            } label: {
                                RecentScanTile(scan: entry.scan, plant: entry.plant)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.xs)
                }
            }
        }
    }
}

private struct RecentScanTile: View {
    let scan: Scan
    let plant: Plant

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: scan.photoUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure, .empty:
                        ZStack {
                            Theme.Color.sage.opacity(0.18)
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Theme.Color.sage)
                        }
                    @unknown default:
                        Theme.Color.sage.opacity(0.18)
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                if scan.isFavorited {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.Color.bone)
                        .padding(6)
                        .background(Theme.Color.ember, in: Circle())
                        .padding(Theme.Spacing.xs)
                }
            }

            Text(plant.commonName)
                .font(Theme.Font.callout)
                .foregroundStyle(Theme.Color.textPrimary)
                .lineLimit(1)
            Text(scan.scannedAt.shortRelativeString)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .frame(width: 120, alignment: .leading)
    }
}
