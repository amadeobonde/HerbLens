import AVKit
import Combine
import SwiftUI
import UIKit

/// Looping, muted, autoplay player for the welcome hero video. Shows a static
/// bamboo image while the first frame buffers — avoids the black flash that
/// `VideoPlayer` produces by default before its first presentation time arrives.
struct VideoBackgroundView: View {
    let resourceName: String
    let resourceExtension: String
    let fallbackImageName: String

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var isReady = false

    var body: some View {
        ZStack {
            if let player {
                PlayerLayerView(player: player)
                    .opacity(isReady ? 1 : 0)
                    .animation(.easeIn(duration: 0.35), value: isReady)
            }
            if !isReady {
                ZStack {
                    Theme.Color.sage.opacity(0.18)
                    Image(fallbackImageName)
                        .resizable()
                        .scaledToFit()
                        .padding(Theme.Spacing.xl)
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            guard player == nil else { return }
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }

    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension) else {
            // Asset missing — keep the static fallback visible.
            return
        }
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer(playerItem: item)
        queue.isMuted = true
        queue.actionAtItemEnd = .advance
        let looper = AVPlayerLooper(player: queue, templateItem: item)

        self.player = queue
        self.looper = looper

        // Flip `isReady` when the item has actually buffered a frame.
        Task { @MainActor in
            for await status in item.publisher(for: \.status).values {
                if status == .readyToPlay {
                    isReady = true
                    queue.play()
                    break
                }
            }
        }
        queue.play()
    }
}

private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerUIView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
