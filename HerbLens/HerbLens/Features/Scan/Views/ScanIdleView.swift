import AVFoundation
import PhotosUI
import SwiftUI

/// Idle camera screen reskinned on the design system. The viewfinder lives inside a
/// `GlassCard` with a peeking `MascotBadge`, the action bar is a `.glass(.subtle)`
/// sticky strip with a `PrimaryButton` shutter and a glass-capsule library picker.
struct ScanIdleView: View {
    let tier: SubscriptionTier
    let remaining: Int?
    let onCapture: (UIImage) -> Void

    @State private var cameraController = CameraCaptureController()
    @State private var pickerItem: PhotosPickerItem?
    @State private var isCapturing: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Color.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                header
                viewfinderCard
                Spacer(minLength: Theme.Spacing.lg)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, 140) // leave room for the sticky bar

            actionBar
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

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Scan a plant")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("Frame a single leaf or bloom for the best match.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            Spacer()
            ScanRemainingChip(tier: tier, remaining: remaining)
        }
    }

    // MARK: - Viewfinder card

    private var viewfinderCard: some View {
        GlassCard {
            ZStack(alignment: .top) {
                viewfinderBody
                    .frame(maxWidth: .infinity)
                    .frame(height: 420)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))

                MascotBadge(.default, size: 72)
                    .offset(y: -36)
            }
        }
        .shadow(Theme.Shadow.card)
    }

    @ViewBuilder
    private var viewfinderBody: some View {
        switch cameraController.authorization {
        case .authorized:
            ZStack {
                CameraPreviewView(session: cameraController.previewSession)
                viewfinderReticle
            }
        case .notDetermined:
            placeholderTint
        default:
            permissionPrompt
        }
    }

    private var viewfinderReticle: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
            .strokeBorder(Theme.Color.bone.opacity(0.7), lineWidth: 2)
            .padding(Theme.Spacing.lg)
    }

    /// Fills the viewfinder card while the camera is not yet authorized or isn't
    /// available (simulator). Apothecary art as a blurred warm backdrop, a big
    /// scanning Bamboo in the center, helpful copy, and a sage dashed reticle so
    /// the composition still reads as a scanner rather than an empty gray box.
    private var placeholderTint: some View {
        ZStack {
            Image("Scenes/Apothecary")
                .resizable()
                .scaledToFill()
                .blur(radius: 18)
                .opacity(0.55)
                .overlay(
                    LinearGradient(
                        colors: [Theme.Color.background.opacity(0.2), Theme.Color.background.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: Theme.Spacing.md) {
                MascotBadge(.scanning, size: 160)

                VStack(spacing: Theme.Spacing.xxs) {
                    Text("Point at any plant")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("We'll identify it in a second.")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }

            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .strokeBorder(
                    Theme.Color.sage.opacity(0.9),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
                .padding(Theme.Spacing.md)
        }
    }

    private var permissionPrompt: some View {
        EmptyStateView(
            mascot: .sleeping,
            title: "Camera access is off",
            subtitle: "Enable camera access in Settings to scan live, or pick a photo from your library."
        )
    }

    // MARK: - Sticky action bar

    private var actionBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            libraryButton
            shutterCTA
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            Color.clear
                .glass(.subtle)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        )
        .shadow(Theme.Shadow.float)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.lg)
    }

    private var libraryButton: some View {
        PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 18, weight: .semibold))
                Text("Library")
                    .font(Theme.Font.callout)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Theme.Color.sage)
            .frame(height: 52)
            .padding(.horizontal, Theme.Spacing.md)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.clear)
                    .glass(.capsule)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Theme.Color.sage, lineWidth: 1.5)
            )
        }
    }

    private var shutterCTA: some View {
        PrimaryButton(
            isCapturing ? "Capturing…" : "Scan plant",
            isDisabled: !cameraController.isReady || isCapturing
        ) {
            Task { @MainActor in await captureFromCamera() }
        }
    }

    // MARK: - Capture flow

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
