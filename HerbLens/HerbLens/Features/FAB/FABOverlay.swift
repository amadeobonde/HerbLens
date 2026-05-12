import SwiftUI

enum FABFlow: Identifiable, Hashable {
    case photoScan
    case barcodeScan
    case plantSearch

    var id: Self { self }
}

struct FABOverlay: View {
    @Binding var isExpanded: Bool
    @Binding var activeFlow: FABFlow?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isExpanded {
                Theme.Color.charcoal.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }
                    .transition(.opacity)
                    .accessibilityLabel("Dismiss")
                    .accessibilityAddTraits(.isButton)
            }

            VStack(alignment: .trailing, spacing: Theme.Spacing.md) {
                if isExpanded {
                    FABActionPanel(
                        onPhotoScan: { selectFlow(.photoScan) },
                        onBarcodeScan: { selectFlow(.barcodeScan) },
                        onSearch: { selectFlow(.plantSearch) }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                FABButton(isExpanded: isExpanded) {
                    withAnimation(Theme.Motion.bounce) {
                        isExpanded.toggle()
                    }
                }
            }
            .padding(.bottom, Theme.Spacing.xl + 64)
            .padding(.trailing, Theme.Spacing.lg)
        }
        .animation(Theme.Motion.bounce, value: isExpanded)
    }

    private func dismiss() {
        withAnimation(Theme.Motion.snappy) {
            isExpanded = false
        }
    }

    private func selectFlow(_ flow: FABFlow) {
        withAnimation(Theme.Motion.snappy) {
            isExpanded = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            activeFlow = flow
        }
    }
}

#Preview {
    @Previewable @State var expanded = true
    @Previewable @State var flow: FABFlow? = nil
    ZStack {
        Theme.Color.background.ignoresSafeArea()
        Text("Tab content behind")
        FABOverlay(isExpanded: $expanded, activeFlow: $flow)
    }
}
