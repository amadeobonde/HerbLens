import SwiftUI

struct HomeGreetingHeader: View {
    let didRefresh: Bool
    let scanCount: Int
    let tier: SubscriptionTier

    @State private var behavior: MascotBehavior = .waving
    @State private var hasSettled = false

    private var greetingCopy: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Late night brew?"
        }
    }

    private var subtitleCopy: String {
        if scanCount == 0 {
            return "Scan your first herb to get started."
        } else if scanCount == 1 {
            return "1 plant identified so far."
        } else {
            return "\(scanCount) plants identified so far."
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            MascotBadge(.default, size: 72, behavior: behavior)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(greetingCopy)
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textPrimary)

                Text(subtitleCopy)
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .task {
            try? await Task.sleep(for: .seconds(1.8))
            behavior = .idle
            hasSettled = true
        }
        .onChange(of: didRefresh) {
            guard hasSettled else { return }
            behavior = .celebrating
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                behavior = .idle
            }
        }
    }
}
