import Foundation
import Testing
@testable import HerbLens

@Suite("ConversationGrouping")
struct ConversationGroupingTests {
    private let now: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 16
        components.hour = 12
        return Calendar(identifier: .gregorian).date(from: components)!
    }()

    @Test("Today bucket")
    func today() {
        let date = now.addingTimeInterval(-60 * 60)
        #expect(ConversationGrouping.bucketForDate(date, now: now) == .today)
    }

    @Test("Yesterday bucket")
    func yesterday() {
        let date = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        #expect(ConversationGrouping.bucketForDate(date, now: now) == .yesterday)
    }

    @Test("This week bucket (3 days ago)")
    func thisWeek() {
        let date = Calendar.current.date(byAdding: .day, value: -3, to: now)!
        #expect(ConversationGrouping.bucketForDate(date, now: now) == .thisWeek)
    }

    @Test("Earlier bucket (30 days ago)")
    func earlier() {
        let date = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        #expect(ConversationGrouping.bucketForDate(date, now: now) == .earlier)
    }

    @Test("Groups respect ordering")
    func groupOrdering() {
        let cal = Calendar(identifier: .gregorian)
        let makeConversation: (String, Date) -> Conversation = { id, date in
            Conversation(
                id: id,
                userId: "u-1",
                startedAt: date,
                lastMessageAt: date,
                contextPlantId: nil,
                messages: []
            )
        }
        let todayConv = makeConversation("today", now.addingTimeInterval(-3600))
        let yesterdayConv = makeConversation("yesterday", cal.date(byAdding: .day, value: -1, to: now)!)
        let earlierConv = makeConversation("earlier", cal.date(byAdding: .day, value: -30, to: now)!)

        let groups = ConversationGrouping.group([yesterdayConv, earlierConv, todayConv], now: now)
        #expect(groups.map(\.bucket) == [.today, .yesterday, .earlier])
    }
}

@Suite("ChatListViewModel")
struct ChatListViewModelTests {
    @Test("Missing user surfaces a friendly failed phase")
    @MainActor
    func missingUserFails() async {
        let vm = ChatListViewModel(
            chat: FakeChatRepository(),
            plants: UnusedListPlantsRepository(),
            auth: StubAuth(userID: nil)
        )
        await vm.load()
        if case .failed(let message) = vm.phase {
            #expect(message.contains("sign in"))
        } else {
            Issue.record("Expected .failed phase")
        }
    }

    @Test("Empty conversation list loads .loaded with no groups")
    @MainActor
    func emptyConversationsLoad() async {
        let vm = ChatListViewModel(
            chat: FakeChatRepository(conversationsFixture: []),
            plants: UnusedListPlantsRepository(),
            auth: StubAuth(userID: "u-1")
        )
        await vm.load()
        #expect(vm.phase == .loaded)
        #expect(vm.groups.isEmpty)
    }
}

private struct UnusedListPlantsRepository: PlantsRepository, @unchecked Sendable {
    func featured() async throws -> [Plant] { [] }
    func plant(id: String) async throws -> Plant {
        throw ServiceError.decodingFailed("unused in list tests")
    }
    func search(query: String) async throws -> [Plant] { [] }
    func healthScore(for plantID: String, userID: String) async throws -> HealthScore {
        throw ServiceError.decodingFailed("unused")
    }
    func highlightCollections() async throws -> [HighlightCollection] { [] }
}
