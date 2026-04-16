import SwiftUI
import UIKit

/// Brew wrap-up screen reached after the last step of `RecipePlayerView`.
/// User snaps a "show off your brew" photo, optionally adds a note, then
/// taps **Add to Vault** which writes a `BrewEntry` to `MadeRecipesStore`
/// (Vault — Agent B3 — replaces this with a real repo when it lands).
struct RecipeFinishView: View {
    let recipe: Recipe
    let madeStore: MadeRecipesStore
    let onSaved: (BrewEntry) -> Void
    let onDismiss: () -> Void

    @State private var camera = RecipeCameraController()
    @State private var capturedImage: UIImage?
    @State private var note: String = ""
    @State private var didSave: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                MascotBadge(.celebrating, size: 140)
                    .padding(.top, Theme.Spacing.lg)

                VStack(spacing: Theme.Spacing.xs) {
                    Text("Show off your brew!")
                        .font(Theme.Font.display)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(recipe.title)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Theme.Spacing.lg)

                photoBlock
                    .padding(.horizontal, Theme.Spacing.md)

                noteField
                    .padding(.horizontal, Theme.Spacing.md)

                PrimaryButton(didSave ? "Saved" : "Add to Vault", isDisabled: didSave) {
                    saveEntry()
                }
                .padding(.horizontal, Theme.Spacing.md)

                PrimaryButton("Skip", variant: .ghost) {
                    onDismiss()
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(
            LinearGradient(
                colors: [Theme.Color.sage.opacity(0.18), Theme.Color.bone],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .swipeDownToDismiss { onDismiss() }
        .task {
            await camera.requestPermissionIfNeeded()
            camera.start()
        }
        .onDisappear { camera.stop() }
    }

    // MARK: - Sections

    @ViewBuilder
    private var photoBlock: some View {
        if let image = capturedImage {
            ZStack(alignment: .topTrailing) {
                GlassCard(tone: .modal) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 280)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                }
                Button {
                    RecipeHaptics.tick()
                    capturedImage = nil
                } label: {
                    Label("Retake", systemImage: Theme.Icon.reset)
                        .font(Theme.Font.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Color.bone)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xxs)
                        .background(Theme.Color.charcoal.opacity(0.7), in: .capsule)
                }
                .padding(Theme.Spacing.md)
            }
        } else {
            cameraBlock
        }
    }

    @ViewBuilder
    private var cameraBlock: some View {
        GlassCard(tone: .modal) {
            VStack(spacing: Theme.Spacing.sm) {
                ZStack {
                    if camera.authorization == .authorized && camera.isReady {
                        RecipeCameraPreviewView(session: camera.previewSession)
                            .frame(height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                    } else if camera.isUnavailable {
                        EmptyStateView(
                            mascot: .sleeping,
                            title: "Camera unavailable",
                            subtitle: "We can't reach the camera right now."
                        )
                        .frame(height: 280)
                    } else {
                        EmptyStateView(
                            mascot: .scanning,
                            title: "Camera access needed",
                            subtitle: "Grant camera access in Settings to capture your brew."
                        )
                        .frame(height: 280)
                    }
                }
                PrimaryButton("Capture") {
                    Task { await capture() }
                }
            }
        }
    }

    private var noteField: some View {
        GlassCard(tone: .subtle) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Notes (optional)")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                TextField("How did it turn out?", text: $note, axis: .vertical)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .lineLimit(2...5)
                    .textFieldStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func capture() async {
        do {
            let image = try await camera.capturePhoto()
            RecipeHaptics.finish()
            capturedImage = image
        } catch {
            RecipeHaptics.tick()
        }
    }

    private func saveEntry() {
        let data = capturedImage?.jpegData(compressionQuality: 0.8)
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = BrewEntry(
            recipeID: recipe.id,
            recipeTitle: recipe.title,
            photoData: data,
            note: trimmed.isEmpty ? nil : trimmed
        )
        madeStore.appendBrew(entry)
        RecipeHaptics.finish()
        didSave = true
        onSaved(entry)
    }
}

#Preview {
    RecipeFinishView(
        recipe: RecipePreviewFixtures.teas.first!,
        madeStore: MadeRecipesStore(defaults: .standard),
        onSaved: { _ in },
        onDismiss: {}
    )
}
