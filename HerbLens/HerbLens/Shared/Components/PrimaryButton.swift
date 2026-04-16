import SwiftUI

/// Full-width capsule button with filled/ghost variants and disabled + pressed states.
/// All four states feed off `Theme` tokens so cross-feature buttons stay coherent.
public struct PrimaryButton: View {
    public enum Variant: Sendable, Hashable {
        case filled
        case ghost
    }

    private nonisolated let title: String
    private nonisolated let variant: Variant
    private nonisolated let isDisabled: Bool
    private nonisolated let action: @Sendable () -> Void

    public nonisolated init(
        _ title: String,
        variant: Variant = .filled,
        isDisabled: Bool = false,
        action: @escaping @Sendable () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Font.callout)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .buttonStyle(PrimaryButtonStyle(variant: variant, isDisabled: isDisabled))
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1.0)
        .animation(Theme.Motion.snappy, value: isDisabled)
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    let variant: PrimaryButton.Variant
    let isDisabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background(background(pressed: configuration.isPressed))
            .clipShape(Capsule(style: .continuous))
            .overlay(strokeOverlay)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(Theme.Motion.snappy, value: configuration.isPressed)
    }

    private var foreground: Color {
        switch variant {
        case .filled: return Theme.Color.bone
        case .ghost:  return Theme.Color.sage
        }
    }

    @ViewBuilder
    private func background(pressed: Bool) -> some View {
        switch variant {
        case .filled:
            Theme.Color.sage
                .brightness(pressed ? -0.04 : 0)
        case .ghost:
            Color.clear
                .glass(.capsule)
        }
    }

    @ViewBuilder
    private var strokeOverlay: some View {
        switch variant {
        case .filled:
            EmptyView()
        case .ghost:
            Capsule(style: .continuous)
                .stroke(Theme.Color.sage, lineWidth: 1.5)
        }
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.md) {
        PrimaryButton("Brew this recipe") {}
        PrimaryButton("Save to vault", variant: .ghost) {}
        PrimaryButton("Locked", variant: .filled, isDisabled: true) {}
        PrimaryButton("Locked ghost", variant: .ghost, isDisabled: true) {}
    }
    .padding()
    .background(Theme.Color.background)
}
