import SwiftUI

/// Streaming thread UI. The view owns a `ChatThreadViewModel` and renders a Bamboo header
/// with optional plant context chip + dismiss button, the messages list with glass /
/// sage-capsule bubbles, the streaming pulse indicator, the error banner, and the input
/// bar. Suggested prompts only appear at the very start of a plant-context conversation.
struct ChatThreadView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ChatThreadViewModel?
    let initialConversation: Conversation

    private let bottomAnchor = "chat-thread-bottom"

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel: viewModel)
            } else {
                ProgressView().tint(Theme.Color.sage)
            }
        }
        .task {
            if viewModel == nil {
                let vm = ChatThreadViewModel(
                    conversation: initialConversation,
                    chat: dependencies.chat,
                    plants: dependencies.plants
                )
                viewModel = vm
                await vm.bootstrap()
            }
        }
        .background(Theme.Color.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear { viewModel?.cancelStream() }
    }

    @ViewBuilder
    private func content(viewModel: ChatThreadViewModel) -> some View {
        VStack(spacing: 0) {
            header(viewModel: viewModel)
            messageScroll(viewModel: viewModel)
            footer(viewModel: viewModel)
        }
    }

    private func header(viewModel: ChatThreadViewModel) -> some View {
        HStack(alignment: .center, spacing: Theme.Spacing.sm) {
            MascotBadge(.teacher, size: 64)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Bamboo")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                if let plant = viewModel.contextPlant {
                    PlantContextChip(plant: plant)
                } else {
                    Text("Your herbal mentor")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Color.textPrimary)
                    .frame(width: 36, height: 36)
                    .glass(.capsule)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close conversation")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
        .padding(.bottom, Theme.Spacing.xs)
    }

    private func messageScroll(viewModel: ChatThreadViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(role: message.role, content: message.content)
                            .id(message.id)
                    }
                    if viewModel.isStreaming {
                        if viewModel.isWaitingForFirstToken {
                            AssistantTypingBubble()
                        } else {
                            MessageBubble(
                                role: .assistant,
                                content: viewModel.streamingBuffer,
                                isStreaming: true
                            )
                        }
                    }
                    Color.clear
                        .frame(height: 1)
                        .id(bottomAnchor)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)
            }
            .onChange(of: viewModel.messages.count) { _, _ in scrollToBottom(proxy) }
            .onChange(of: viewModel.streamingBuffer) { _, _ in scrollToBottom(proxy) }
            .onChange(of: viewModel.isWaitingForFirstToken) { _, _ in scrollToBottom(proxy) }
        }
    }

    private func footer(viewModel: ChatThreadViewModel) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            if let error = viewModel.errorBanner {
                ChatErrorBanner(message: error) {
                    viewModel.dismissError()
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            if let plant = viewModel.contextPlant,
               viewModel.messages.isEmpty || viewModel.messages.count <= 1 {
                if !plant.suggestedPrompts.isEmpty {
                    SuggestedPromptsRow(prompts: plant.suggestedPrompts) { prompt in
                        viewModel.insertPrompt(prompt)
                    }
                }
            }
            ChatInputBar(
                draft: Binding(
                    get: { viewModel.draft },
                    set: { viewModel.draft = $0 }
                ),
                canSend: !viewModel.isStreaming
                    && !viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                onSend: viewModel.send
            )
        }
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Color.background)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.15)) {
            proxy.scrollTo(bottomAnchor, anchor: .bottom)
        }
    }
}
