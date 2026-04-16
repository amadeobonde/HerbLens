import SwiftUI

/// Generic glass-surface container. Applies a Liquid Glass role + corner radius +
/// resting card shadow + interior padding so feature views can drop content in
/// without re-deriving the brand chrome each time.
public struct GlassCard<Content: View>: View {
    public enum Tone: Sendable, Hashable {
        case standard
        case modal
        case subtle
    }

    private let tone: Tone
    private let content: Content

    // Note: not `nonisolated` because `Content` (an arbitrary SwiftUI `View`) isn't
    // required to be `Sendable`. Construct on the main actor like every other SwiftUI view.
    public init(tone: Tone = .standard, @ViewBuilder content: () -> Content) {
        self.tone = tone
        self.content = content()
    }

    public var body: some View {
        content
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glass(role)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .shadow(Theme.Shadow.card)
    }

    private var role: Theme.Glass.Role {
        switch tone {
        case .standard: return .card
        case .modal:    return .modal
        case .subtle:   return .subtle
        }
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.md) {
        GlassCard {
            Text("Standard glass card")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
        }
        GlassCard(tone: .subtle) {
            Text("Subtle wash")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        GlassCard(tone: .modal) {
            Text("Modal chrome")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
        }
    }
    .padding()
    .background(Theme.Color.background)
}
