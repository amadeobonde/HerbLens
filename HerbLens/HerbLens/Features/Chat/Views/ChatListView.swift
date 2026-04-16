import SwiftUI

/// Conversation list. Sections group by `ChatDateBucket`; tapping a row pushes a thread
/// view via the parent `NavigationStack`. The empty state uses the shared `EmptyStateView`
/// so Bamboo, headline, body copy, and CTA all match the rest of the app.
struct ChatListView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: ChatListViewModel?
    let onSelect: (Conversation) -> Void
    let onStartBlank: @Sendable () -> Void

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
            EmptyStateView(
                mascot: .teacher,
                title: "Ask Bamboo anything",
                subtitle: "Tap a plant or start fresh.",
                ctaTitle: "New conversation",
                action: onStartBlank
            )
        case .loaded:
            loadedList(viewModel: viewModel)
        case .failed(let message):
            failedState(message: message, viewModel: viewModel)
        }
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
                                plantName: viewModel.plantName(for: conversation.contextPlantId),
                                plantThumbnailURL: viewModel.plantThumbnailURL(for: conversation.contextPlantId)
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(
                            top: Theme.Spacing.xxs,
                            leading: Theme.Spacing.md,
                            bottom: Theme.Spacing.xxs,
                            trailing: Theme.Spacing.md
                        ))
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
                .foregroundStyle(Theme.Color.textPrimary)
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
