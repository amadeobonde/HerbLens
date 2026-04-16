@preconcurrency import AVFoundation
import Observation
import UIKit

/// Owns the live `AVCaptureSession` behind `CameraPreviewView`. All session mutations
/// happen on a dedicated serial queue per Apple's guidance; published UI state hops
/// back to the main actor so SwiftUI observes a consistent world.
@Observable
@MainActor
public final class CameraCaptureController: NSObject {
    public enum CameraError: Error, Sendable {
        case notAuthorized
        case unavailable
        case captureFailed
    }

    public private(set) var authorization: AVAuthorizationStatus
    public private(set) var isReady: Bool = false
    public private(set) var lastError: CameraError?

    @ObservationIgnored private let session = AVCaptureSession()
    @ObservationIgnored private let photoOutput = AVCapturePhotoOutput()
    @ObservationIgnored private let sessionQueue = DispatchQueue(label: "app.herblens.scan.session")
    @ObservationIgnored private var photoContinuation: CheckedContinuation<UIImage, Error>?

    public var previewSession: AVCaptureSession { session }

    public override init() {
        self.authorization = AVCaptureDevice.authorizationStatus(for: .video)
        super.init()
    }

    public func requestPermissionIfNeeded() async {
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

    public func start() {
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
            if session.outputs.isEmpty, session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                photoOutput.maxPhotoQualityPrioritization = .balanced
            }
            session.commitConfiguration()
            session.startRunning()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.isReady = !session.inputs.isEmpty
            }
        }
    }

    public func stop() {
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    public func capturePhoto() async throws -> UIImage {
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

extension CameraCaptureController: AVCapturePhotoCaptureDelegate {
    public nonisolated func photoOutput(
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
