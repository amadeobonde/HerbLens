import SwiftUI

/// Rounded-bottom photo cap used at the top of hero/detail screens. Bottom corners are
/// the only ones rounded (24pt), and a vertical gradient blends the photo into the
/// page background so headline content reads cleanly over the lower portion.
public struct HeroPhoto: View {
    private nonisolated let uiImage: UIImage?
    private nonisolated let named: String?
    private nonisolated let height: CGFloat

    public nonisolated init(uiImage: UIImage? = nil, named: String? = nil, height: CGFloat = 280) {
        self.uiImage = uiImage
        self.named = named
        self.height = height
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            photo
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                stops: [
                    .init(color: Color.clear, location: 0.0),
                    .init(color: Color.clear, location: 0.6),
                    .init(color: Theme.Color.background.opacity(0.95), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: height)
        .clipShape(BottomRoundedShape(radius: 24))
    }

    @ViewBuilder
    private var photo: some View {
        if let uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if let named {
            Image(named)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Theme.Color.sage.opacity(0.25)
        }
    }
}

/// Shape that rounds only the bottom-leading and bottom-trailing corners.
private struct BottomRoundedShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let r = min(radius, min(rect.width, rect.height) / 2)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
            radius: r,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        p.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        p.closeSubpath()
        return p
    }
}

#Preview {
    VStack(spacing: 0) {
        HeroPhoto(named: "Scenes/Apothecary", height: 280)
        Spacer()
    }
    .background(Theme.Color.background)
    .ignoresSafeArea(edges: .top)
}
