import SwiftUI

struct PlantSearchView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PlantSearchViewModel?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)
                    .padding(.bottom, Theme.Spacing.md)

                Divider()
                    .foregroundStyle(Theme.Color.sage.opacity(0.2))

                searchContent
            }
            .background(Theme.Color.background.ignoresSafeArea())
            .navigationTitle("Search plants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: Theme.Icon.close)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = PlantSearchViewModel(plants: dependencies.plants)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: Theme.Icon.search)
                .font(.system(size: 16))
                .foregroundStyle(Theme.Color.textSecondary)

            TextField("Search herbs, plants, remedies…", text: queryBinding)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textPrimary)
                .autocorrectionDisabled()

            if let vm = viewModel, !vm.query.isEmpty {
                Button {
                    vm.clear()
                } label: {
                    Image(systemName: Theme.Icon.close)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Color.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(Theme.Color.sage.opacity(0.12))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .glass(.capsule)
    }

    @ViewBuilder
    private var searchContent: some View {
        switch viewModel?.state ?? .idle {
        case .idle:
            idleContent
        case .searching:
            VStack {
                Spacer()
                ProgressView()
                    .tint(Theme.Color.sage)
                Spacer()
            }
        case .results(let plants):
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.xs) {
                    ForEach(plants) { plant in
                        PlantSearchRow(plant: plant)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.sm)
            }
        case .empty:
            VStack(spacing: Theme.Spacing.md) {
                Spacer()
                Image(systemName: "leaf.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Color.sage.opacity(0.4))
                Text("No plants found")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("Try a different name or spelling")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                Spacer()
            }
        }
    }

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("Popular searches")
                .font(Theme.Font.callout.weight(.semibold))
                .foregroundStyle(Theme.Color.textSecondary)
                .padding(.horizontal, Theme.Spacing.md)

            let suggestions = ["Chamomile", "Lavender", "Peppermint", "Echinacea", "Ginger", "Dandelion"]
            SearchFlowLayout(spacing: Theme.Spacing.xs) {
                ForEach(suggestions, id: \.self) { name in
                    Button {
                        viewModel?.query = name
                    } label: {
                        Text(name)
                            .font(Theme.Font.callout)
                            .foregroundStyle(Theme.Color.forest)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.xs)
                            .glass(.capsule)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)

            Spacer()
        }
        .padding(.top, Theme.Spacing.lg)
    }

    private var queryBinding: Binding<String> {
        Binding(
            get: { viewModel?.query ?? "" },
            set: { viewModel?.query = $0 }
        )
    }
}

private struct PlantSearchRow: View {
    let plant: Plant

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            AsyncImage(url: URL(string: plant.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(Theme.Color.sage.opacity(0.12))
                    .overlay {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(Theme.Color.sage.opacity(0.4))
                    }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(plant.commonName)
                    .font(Theme.Font.callout.weight(.semibold))
                    .foregroundStyle(Theme.Color.textPrimary)

                Text(plant.category)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }

            Spacer()

            Image(systemName: Theme.Icon.next)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .contentShape(Rectangle())
    }
}

private struct SearchFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            guard index < result.positions.count else { break }
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    PlantSearchView()
        .environment(\.dependencies, .mock)
}
