import Foundation

/// Discriminated load state for the home feed. View renders a skeleton on `.loading`,
/// the real feed on `.loaded`, and a retry surface on `.failed`.
public nonisolated enum HomeLoadState: Sendable, Equatable {
    case idle
    case loading
    case loaded(HomeData)
    case failed(String)
}
