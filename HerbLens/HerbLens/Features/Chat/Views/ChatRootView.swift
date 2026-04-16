import SwiftUI

/// Single entry point for the Chat feature. Checks the current subscription tier; free
/// users see `ChatPaywallPromo`, premium users see either the conversation list (when
/// `contextPlantID == nil`) or a deep-linked thread view (when pushed from HerbProfile).
///
/// Navigation between the list and thread is managed by a `NavigationStack` path, so
/// deep-linked threads still back-swipe to the list when the user chose that flow.
struct ChatRootView: View {
    @Environment(\.dependencies) private var dependencies
    let contextPlantID: String?
    var onUpgradeTapped: () -> Void = {}

    @State private var tier: SubscriptionTier?
    @State private var path = NavigationPath()
    @State private var deepLinkError: String?
    @State private var didResolveDeepLink = false

    var body: some View {
        NavigationStack(path: $path) {
            rootContent
                .navigationDestination(for: Conversation.self) { conversation in
                    ChatThreadView(initialConversation: conversation)
                }
        }
        .task {
            if tier == nil {
                tier = await dependencies.subscriptions.currentTier()
            }
        }
        .task(id: tier) {
            guard tier == .premium,
                  let plantID = contextPlantID,
                  !didResolveDeepLink else { return }
            await openDeepLink(plantID: plantID)
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        switch tier {
        case .none:
            ProgressView().tint(Theme.Color.sage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Color.background)
        case .free:
            ChatPaywallPromo(onUpgradeTapped: onUpgradeTapped)
        case .premium:
            listOrError
        }
    }

    private var listOrError: some View {
        ChatListView(
            onSelect: { conversation in
                path.append(conversation)
            },
            onStartBlank: {
                Task { await startNewConversation(contextPlantID: nil) }
            }
        )
        .overlay(alignment: .top) {
            if let deepLinkError {
                ChatErrorBanner(message: deepLinkError) {
                    self.deepLinkError = nil
                }
                .padding(Theme.Spacing.md)
            }
        }
    }

    private func openDeepLink(plantID: String) async {
        didResolveDeepLink = true
        guard let userID = await dependencies.auth.currentUserID else {
            deepLinkError = "Please sign in to chat about this plant."
            return
        }
        do {
            let conversation = try await dependencies.chat.startConversation(
                userID: userID,
                contextPlantID: plantID
            )
            path.append(conversation)
        } catch {
            deepLinkError = ChatThreadViewModel.friendly(error)
        }
    }

    private func startNewConversation(contextPlantID: String?) async {
        guard let userID = await dependencies.auth.currentUserID else {
            deepLinkError = "Please sign in to start a conversation."
            return
        }
        do {
            let conversation = try await dependencies.chat.startConversation(
                userID: userID,
                contextPlantID: contextPlantID
            )
            path.append(conversation)
        } catch {
            deepLinkError = ChatThreadViewModel.friendly(error)
        }
    }
}
