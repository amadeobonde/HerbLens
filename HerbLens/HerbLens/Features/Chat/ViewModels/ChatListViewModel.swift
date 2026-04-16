import Foundation
import Observation

/// Drives `ChatListView`. Loads the user's conversations, groups them by date, and
/// resolves context-plant names for each row's subtitle.
@MainActor
@Observable
final class ChatListViewModel {
    enum Phase: Sendable, Hashable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var groups: [ConversationGroup] = []
    private(set) var plantNames: [String: String] = [:]

    private let chat: any ChatRepository
    private let plants: any PlantsRepository
    private let auth: any AuthService

    init(
        chat: any ChatRepository,
        plants: any PlantsRepository,
        auth: any AuthService
    ) {
        self.chat = chat
        self.plants = plants
        self.auth = auth
    }

    func load(now: Date = .now) async {
        phase = .loading
        do {
            guard let userID = await auth.currentUserID else {
                phase = .failed("Please sign in to see your chats.")
                return
            }
            let conversations = try await chat.conversations(userID: userID)
            let grouped = ConversationGrouping.group(conversations, now: now)
            let plantIDs = Set(conversations.compactMap { $0.contextPlantId })
            let names = await resolvePlantNames(ids: plantIDs)
            groups = grouped
            plantNames = names
            phase = .loaded
        } catch {
            phase = .failed(Self.friendly(error))
        }
    }

    func plantName(for contextPlantId: String?) -> String? {
        guard let contextPlantId else { return nil }
        return plantNames[contextPlantId]
    }

    private func resolvePlantNames(ids: Set<String>) async -> [String: String] {
        var result: [String: String] = [:]
        for id in ids {
            if let plant = try? await plants.plant(id: id) {
                result[id] = plant.commonName
            }
        }
        return result
    }

    nonisolated static func friendly(_ error: Error) -> String {
        if let service = error as? ServiceError {
            switch service {
            case .unauthenticated: return "Please sign in to see your chats."
            case .httpStatus(let code, _): return "Couldn't load chats (status \(code))."
            case .decodingFailed: return "Couldn't read the server response."
            case .malformedURL: return "Server address is misconfigured."
            }
        }
        return "Something went wrong. Pull to refresh."
    }
}
