import SwiftUI

/// Circular progress ring used for health scores, brewing timers, and any 0–1 metric.
/// Background ring sits at low opacity so the colored arc reads as the dominant signal;
/// center text shows the percentage with a caption label below.
public struct RingMetric: View {
    private nonisolated let value: Double
    private nonisolated let total: Double
    private nonisolated let label: String
    private nonisolated let color: Color

    public nonisolated init(
        value: Double,
        total: Double = 1.0,
        label: String,
        color: Color
    ) {
        self.value = value
        self.total = total
        self.label = label
        self.color = color
    }

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(max(value / total, 0), 1)
    }

    public var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    let dim = min(geo.size.width, geo.size.height)
                    let strokeWidth = max(2, dim / 10)

                    ZStack {
                        Circle()
                            .stroke(Theme.Color.bone.opacity(0.6), lineWidth: strokeWidth)

                        Circle()
                            .trim(from: 0, to: fraction)
                            .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(Theme.Motion.gentle, value: fraction)

                        VStack(spacing: 2) {
                            Text("\(Int((fraction * 100).rounded()))%")
                                .font(.system(size: max(10, dim * 0.28), weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.Color.textPrimary)
                            Text(label)
                                .font(.system(size: max(8, dim * 0.13), weight: .medium, design: .default))
                                .foregroundStyle(Theme.Color.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .frame(width: dim, height: dim)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
    }
}

#Preview {
    HStack(spacing: Theme.Spacing.lg) {
        RingMetric(value: 0.82, label: "Sleep", color: Theme.Color.sage)
        RingMetric(value: 0.45, label: "Energy", color: Theme.Color.amber)
        RingMetric(value: 0.18, label: "Caution", color: Theme.Color.ember)
    }
    .padding()
    .background(Theme.Color.background)
}
