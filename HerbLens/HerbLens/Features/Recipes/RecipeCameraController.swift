@preconcurrency import AVFoundation
import Observation
import UIKit

/// Recipes-local camera controller used by the finish view's "show off your brew"
/// shot. Keeps Recipes self-contained — Scan (Agent B1) owns the canonical
/// `CameraCaptureController` under `Features/Scan/Camera/`, but cross-feature
/// imports aren't allowed under §4 of the project ownership rules. Once a
/// shared `Shared/Camera/` lands, this file collapses to a thin alias.
@Observable
@MainActor
final class RecipeCameraController: NSObject {
    enum CameraError: Error, Sendable {
        case notAuthorized
        case unavailable
        case captureFailed
    }

    private(set) var authorization: AVAuthorizationStatus
    private(set) var isReady: Bool = false
    private(set) var isUnavailable: Bool = false
    private(set) var lastError: CameraError?

    @ObservationIgnored private let session = AVCaptureSession()
    @ObservationIgnored private let photoOutput = AVCapturePhotoOutput()
    @ObservationIgnored private let sessionQueue = DispatchQueue(label: "app.herblens.recipes.session")
    @ObservationIgnored private var photoContinuation: CheckedContinuation<UIImage, Error>?

    var previewSession: AVCaptureSession { session }

    override init() {
        self.authorization = AVCaptureDevice.authorizationStatus(for: .video)
        super.init()
    }

    func requestPermissionIfNeeded() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            authorization = .authorized
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorization = granted ? .authorized : .denied
        case .denied, .restricted:
            authorization = .denied
        @unknown default:
            authorization = .denied
        }
    }

    func start() {
        guard authorization == .authorized else { return }
        sessionQueue.async { [session, photoOutput] in
            if session.isRunning { return }
            session.beginConfiguration()
            session.sessionPreset = .photo
            if session.inputs.isEmpty {
                if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                   let input = try? AVCaptureDeviceInput(device: device),
                   session.canAddInput(input) {
                    session.addInput(input)
                }
            }
            let hasInput = !session.inputs.isEmpty
            if hasInput, session.outputs.isEmpty, session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                photoOutput.maxPhotoQualityPrioritization = .balanced
            }
            session.commitConfiguration()
            if hasInput { session.startRunning() }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.isReady = hasInput
                self.isUnavailable = !hasInput
            }
        }
    }

    func stop() {
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    func capturePhoto() async throws -> UIImage {
        guard authorization == .authorized else { throw CameraError.notAuthorized }
        guard isReady else { throw CameraError.unavailable }

        return try await withCheckedThrowingContinuation { continuation in
            self.photoContinuation = continuation
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            settings.photoQualityPrioritization = .balanced
            sessionQueue.async { [photoOutput, weak self] in
                guard let self else { return }
                photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }
}

extension RecipeCameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let data = photo.fileDataRepresentation()
        Task { @MainActor [weak self] in
            guard let self else { return }
            let continuation = self.photoContinuation
            self.photoContinuation = nil
            if let error {
                continuation?.resume(throwing: error)
                return
            }
            guard let data, let image = UIImage(data: data) else {
                continuation?.resume(throwing: CameraError.captureFailed)
                return
            }
            continuation?.resume(returning: image)
        }
    }
}

/// SwiftUI preview wrapper for `RecipeCameraController`'s live `AVCaptureSession`.
/// The preview layer fills the host view; the controller drives orientation +
/// session lifecycle.
struct RecipeCameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
