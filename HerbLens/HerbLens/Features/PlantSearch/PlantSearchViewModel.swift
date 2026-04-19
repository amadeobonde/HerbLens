import Foundation

@Observable @MainActor
final class PlantSearchViewModel {
    enum SearchState: Equatable {
        case idle
        case searching
        case results([Plant])
        case empty
    }

    var query: String = "" {
        didSet { debounceSearch() }
    }
    private(set) var state: SearchState = .idle

    private let plants: any PlantsRepository
    private var searchTask: Task<Void, Never>?

    nonisolated init(plants: any PlantsRepository) {
        self.plants = plants
    }

    private func debounceSearch() {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            return
        }

        state = .searching
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            do {
                let results = try await plants.search(query: trimmed)
                guard !Task.isCancelled else { return }
                state = results.isEmpty ? .empty : .results(results)
            } catch {
                guard !Task.isCancelled else { return }
                state = .empty
            }
        }
    }

    func clear() {
        query = ""
        state = .idle
        searchTask?.cancel()
    }
}
