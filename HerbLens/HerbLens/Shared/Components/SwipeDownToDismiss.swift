import SwiftUI

/// Drag-to-dismiss gesture modifier. Tracks a vertical drag, slides + scales the host
/// view as the user pulls down, and fires `onDismiss` once translation crosses
/// `threshold` *and* the gesture is moving downward at release. Cancels (springs back)
/// when the user releases below the threshold or drags upward.
public extension View {
    func swipeDownToDismiss(
        threshold: CGFloat = 120,
        onDismiss: @escaping @Sendable () -> Void
    ) -> some View {
        modifier(SwipeDownToDismissModifier(threshold: threshold, onDismiss: onDismiss))
    }
}

private struct SwipeDownToDismissModifier: ViewModifier {
    let threshold: CGFloat
    let onDismiss: @Sendable () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    func body(content: Content) -> some View {
        content
            .offset(y: max(dragOffset, 0))
            .scaleEffect(scaleFactor, anchor: .center)
            .animation(Theme.Motion.snappy, value: dragOffset)
            .gesture(dragGesture)
    }

    private var scaleFactor: CGFloat {
        guard dragOffset > 0 else { return 1 }
        let progress = min(dragOffset / (threshold * 2), 1)
        return 1 - 0.05 * progress
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation.height
            }
            .onEnded { value in
                isDragging = false
                let movingDown = value.predictedEndTranslation.height > value.translation.height
                if value.translation.height > threshold && movingDown {
                    withAnimation(Theme.Motion.snappy) {
                        // Large value ensures the view slides fully off-screen; precise
                        // screen height isn't needed — modifier host is typically dismissed
                        // in the onDismiss callback immediately after.
                        dragOffset = 2000
                    }
                    onDismiss()
                } else {
                    withAnimation(Theme.Motion.snappy) {
                        dragOffset = 0
                    }
                }
            }
    }
}

#Preview {
    VStack {
        Text("Drag down to dismiss")
            .font(Theme.Font.title)
            .padding()
            .background(Theme.Color.bone)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.Color.background)
    .swipeDownToDismiss { }
}
