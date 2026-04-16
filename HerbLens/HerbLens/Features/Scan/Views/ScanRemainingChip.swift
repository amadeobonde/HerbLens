import SwiftUI

/// Small capsule that communicates tier + quota at a glance. Premium users see an
/// "unlimited" chip; free users see remaining scans for today.
struct ScanRemainingChip: View {
    let tier: SubscriptionTier
    let remaining: Int?

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .semibold))
            Text(label)
                .font(Theme.Font.caption)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xxs)
        .background(Capsule().fill(background))
        .overlay(Capsule().stroke(foreground.opacity(0.25), lineWidth: 0.5))
    }

    private var iconName: String {
        switch tier {
        case .premium: return "sparkles"
        case .free: return "camera.viewfinder"
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

    private var background: Color {
        switch tier {
        case .premium: return Theme.Color.bone.opacity(0.9)
        case .free:
            if let remaining, remaining == 0 { return Theme.Color.ember.opacity(0.12) }
            return Theme.Color.amber.opacity(0.18)
        }
    }
}
