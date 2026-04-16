import SwiftUI

/// Top-of-feed greeting: Bamboo at left, time-of-day greeting at right. The mascot
/// rotates a full turn whenever `rotation` changes — `HomeView` bumps it from
/// `refreshable` so pulling to refresh produces a snappy mascot spin.
struct HomeGreetingHeader: View {
    let rotation: Double

    private var greetingCopy: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning, let's brew."
        case 12..<17: return "Good afternoon, let's brew."
        case 17..<22: return "Good evening, let's brew."
        default: return "Late night, let's brew."
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            MascotBadge(.default, size: 80)
                .rotationEffect(.degrees(rotation))
                .animation(Theme.Motion.snappy, value: rotation)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(greetingCopy)
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
}
