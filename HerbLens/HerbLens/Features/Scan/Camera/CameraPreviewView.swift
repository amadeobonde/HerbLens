import AVFoundation
import SwiftUI
import UIKit

/// SwiftUI wrapper around `AVCaptureVideoPreviewLayer`. The backing view's layer *is*
/// the preview layer (see `layerClass` override), which is the idiomatic way to size
/// the preview with Auto Layout without juggling a separate sublayer.
public struct CameraPreviewView: UIViewRepresentable {
    public let session: AVCaptureSession
    public let videoGravity: AVLayerVideoGravity

    public init(session: AVCaptureSession, videoGravity: AVLayerVideoGravity = .resizeAspectFill) {
        self.session = session
        self.videoGravity = videoGravity
    }

    public func makeUIView(context: Context) -> VideoPreviewContainer {
        let view = VideoPreviewContainer()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = videoGravity
        return view
    }

    public func updateUIView(_ uiView: VideoPreviewContainer, context: Context) {
        uiView.previewLayer.session = session
        uiView.previewLayer.videoGravity = videoGravity
    }
}

public final class VideoPreviewContainer: UIView {
    public override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    public var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
