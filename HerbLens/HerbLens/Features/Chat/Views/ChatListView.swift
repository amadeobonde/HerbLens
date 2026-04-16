import SwiftUI

/// Conversation list. Sections group by `ChatDateBucket`; tapping a row pushes a thread
/// view via the parent `NavigationStack`. The empty state uses Bamboo as the focal point
/// and offers a CTA to start a fresh conversation.
struct ChatListView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: ChatListViewModel?
    let onSelect: (Conversation) -> Void
    let onStartBlank: () -> Void

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
                viewModel = ChatListViewModel(
                    chat: dependencies.chat,
                    plants: dependencies.plants,
                    auth: dependencies.auth
                )
                await viewModel?.load()
            }
        }
        .background(Theme.Color.background.ignoresSafeArea())
        .navigationTitle("Bamboo")
    }

    @ViewBuilder
    private func content(viewModel: ChatListViewModel) -> some View {
        switch viewModel.phase {
        case .idle, .loading:
            VStack {
                Spacer()
                ProgressView().tint(Theme.Color.sage)
                Spacer()
            }
        case .loaded where viewModel.groups.isEmpty:
            emptyState
        case .loaded:
            loadedList(viewModel: viewModel)
        case .failed(let message):
            failedState(message: message, viewModel: viewModel)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()
            BambooAvatarView(size: 120)
            Text("Your chat with Bamboo is quiet")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.charcoal)
            Text("Ask anything — brewing, safety, the best herb for your goals.")
                .font(Theme.Font.callout)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)
            Button {
                onStartBlank()
            } label: {
                Text("Start a conversation")
                    .font(Theme.Font.callout.weight(.semibold))
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.Color.forest, in: Capsule())
                    .foregroundStyle(Theme.Color.bone)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadedList(viewModel: ChatListViewModel) -> some View {
        List {
            ForEach(viewModel.groups) { group in
                Section {
                    ForEach(group.conversations) { conversation in
                        Button {
                            onSelect(conversation)
                        } label: {
                            ChatConversationRow(
                                conversation: conversation,
                                plantName: viewModel.plantName(for: conversation.contextPlantId)
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.Color.background)
                    }
                } header: {
                    Text(group.bucket.title)
                        .font(Theme.Font.caption.weight(.semibold))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            await viewModel.load()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onStartBlank) {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(Theme.Color.forest)
                }
                .accessibilityLabel("New conversation")
            }
        }
    }

    private func failedState(message: String, viewModel: ChatListViewModel) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(Theme.Color.ember)
            Text(message)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.charcoal)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)
            Button("Try again") {
                Task { await viewModel.load() }
            }
            .buttonStyle(.bordered)
            .tint(Theme.Color.forest)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
