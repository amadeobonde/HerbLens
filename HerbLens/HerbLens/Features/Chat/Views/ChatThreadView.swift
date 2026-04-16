import SwiftUI

/// Streaming thread UI. The view owns a `ChatThreadViewModel` and renders the messages
/// list, the typing indicator, the live streaming bubble, the error banner, optional
/// plant context + suggested prompts, and the input bar.
struct ChatThreadView: View {
    @Environment(\.dependencies) private var dependencies
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
        .navigationTitle(initialConversation.contextPlantId == nil ? "Bamboo" : "Bamboo • plant chat")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { viewModel?.cancelStream() }
    }

    @ViewBuilder
    private func content(viewModel: ChatThreadViewModel) -> some View {
        VStack(spacing: 0) {
            messageScroll(viewModel: viewModel)
            footer(viewModel: viewModel)
        }
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
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    PlantContextChip(plant: plant)
                        .padding(.horizontal, Theme.Spacing.md)
                    if !plant.suggestedPrompts.isEmpty {
                        SuggestedPromptsRow(prompts: plant.suggestedPrompts) { prompt in
                            viewModel.insertPrompt(prompt)
                        }
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
