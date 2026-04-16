import AVFoundation
import PhotosUI
import SwiftUI

/// Idle camera screen: live AVCapture preview (or a permission prompt) plus a bottom
/// control bar with shutter + PhotosPicker fallback + tier/quota chip.
struct ScanIdleView: View {
    let tier: SubscriptionTier
    let remaining: Int?
    let onCapture: (UIImage) -> Void

    @State private var cameraController = CameraCaptureController()
    @State private var pickerItem: PhotosPickerItem?
    @State private var isCapturing: Bool = false

    var body: some View {
        ZStack {
            backgroundLayer

            VStack {
                topChrome
                Spacer()
                controlBar
            }
        }
        .task {
            await cameraController.requestPermissionIfNeeded()
            cameraController.start()
        }
        .onDisappear {
            cameraController.stop()
        }
        .onChange(of: pickerItem) {
            guard let item = pickerItem else { return }
            Task { await handlePickerSelection(item) }
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        switch cameraController.authorization {
        case .authorized:
            CameraPreviewView(session: cameraController.previewSession)
                .ignoresSafeArea()
        case .notDetermined:
            Theme.Color.background.ignoresSafeArea()
        default:
            permissionPrompt
        }
    }

    private var permissionPrompt: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "camera.metering.unknown")
                    .font(.system(size: 54))
                    .foregroundStyle(Theme.Color.forest)
                Text("Camera access is off")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("Enable camera access in Settings to scan live, or pick a photo from your library.")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }
            .padding(Theme.Spacing.xl)
        }
    }

    private var topChrome: some View {
        HStack {
            Spacer()
            ScanRemainingChip(tier: tier, remaining: remaining)
                .padding(.trailing, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.xs)
        }
    }

    private var controlBar: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.lg) {
            PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Theme.Color.bone)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Theme.Color.forest.opacity(0.9)))
            }

            shutterButton

            Color.clear
                .frame(width: 56, height: 56)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.xl)
    }

    private var shutterButton: some View {
        Button {
            Task { await captureFromCamera() }
        } label: {
            ZStack {
                Circle()
                    .stroke(Theme.Color.bone, lineWidth: 4)
                    .frame(width: 80, height: 80)
                Circle()
                    .fill(Theme.Color.bone)
                    .frame(width: 64, height: 64)
                    .scaleEffect(isCapturing ? 0.85 : 1)
            }
        }
        .disabled(!cameraController.isReady || isCapturing)
        .opacity(cameraController.isReady ? 1 : 0.4)
        .animation(.easeInOut(duration: 0.12), value: isCapturing)
    }

    private func captureFromCamera() async {
        guard !isCapturing else { return }
        isCapturing = true
        ScanHaptics.shutter()
        defer { isCapturing = false }
        do {
            let image = try await cameraController.capturePhoto()
            onCapture(image)
        } catch {
            // Non-fatal: user can retry. Errors from the identify path surface via
            // ScanViewModel.
        }
    }

    private func handlePickerSelection(_ item: PhotosPickerItem) async {
        defer { pickerItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        onCapture(image)
    }
}
