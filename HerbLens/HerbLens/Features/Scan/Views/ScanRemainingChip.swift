import SwiftUI

/// Small capsule that communicates tier + quota at a glance. Premium users see an
/// "unlimited" chip; free users see remaining scans for today. Uses the shared
/// `.glass(.capsule)` chrome and Bamboo's mascot rather than an SF symbol.
struct ScanRemainingChip: View {
    let tier: SubscriptionTier
    let remaining: Int?

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            mascotHead
            Text(label)
                .font(Theme.Font.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xxs)
        .background(
            Capsule(style: .continuous)
                .fill(Color.clear)
                .glass(.capsule)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(foreground.opacity(0.25), lineWidth: 0.5)
        )
        .shadow(Theme.Shadow.card)
    }

    private var mascotHead: some View {
        Image(mascotAsset)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 22, height: 22)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Theme.Color.bone.opacity(0.7), lineWidth: 1)
            )
    }

    private var mascotAsset: String {
        switch tier {
        case .premium:
            return MascotBadge.Variant.celebrating.rawValue
        case .free:
            if let remaining, remaining == 0 {
                return MascotBadge.Variant.sleeping.rawValue
            }
            return MascotBadge.Variant.default.rawValue
        }
    }

    private var label: String {
        switch tier {
        case .premium:
            return "Premium · unlimited"
        case .free:
            if let remaining {
                return "\(remaining) scan\(remaining == 1 ? "" : "s") left today"
            }
            return "Free tier"
        }
    }

    private var foreground: Color {
        switch tier {
        case .premium: return Theme.Color.forest
        case .free:
            if let remaining, remaining == 0 { return Theme.Color.ember }
            return Theme.Color.textPrimary
        }
    }
}
