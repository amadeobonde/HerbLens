import SwiftUI

/// Hero image with classic iOS parallax: stretches on overscroll, subtly offsets when
/// pinned. Uses `visualEffect` to read the scroll proxy without re-rendering the view.
struct HeroParallaxHeader: View {
    let plant: Plant
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            imageLayer
            gradientScrim
            titleBlock
        }
        .frame(height: height)
        .clipped()
    }

    private var imageLayer: some View {
        AsyncImage(url: URL(string: plant.imageUrl)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .empty:
                Theme.Color.surface.opacity(0.35)
                    .overlay(ProgressView().tint(Theme.Color.forest))
            case .failure:
                Theme.Color.surface
                    .overlay(
                        Image(systemName: "leaf")
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(Theme.Color.forest.opacity(0.4))
                    )
            @unknown default:
                Theme.Color.surface
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .visualEffect { content, proxy in
            let minY = proxy.bounds(of: .scrollView)?.minY ?? 0
            return content
                .scaleEffect(minY < 0 ? 1 + abs(minY) / 400 : 1, anchor: .top)
                .offset(y: minY < 0 ? minY / 2 : 0)
        }
    }

    private var gradientScrim: some View {
        LinearGradient(
            colors: [.black.opacity(0), .black.opacity(0.55)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: height * 0.6)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(false)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(plant.category.uppercased())
                .font(Theme.Font.caption.weight(.semibold))
                .foregroundStyle(Theme.Color.bone.opacity(0.85))
                .tracking(1.4)
            Text(plant.commonName)
                .font(Theme.Font.display)
                .foregroundStyle(Theme.Color.bone)
                .lineLimit(2)
            if let first = plant.alternateNames.first {
                Text(first)
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.bone.opacity(0.8))
                    .italic()
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.lg)
        .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
    }
}
