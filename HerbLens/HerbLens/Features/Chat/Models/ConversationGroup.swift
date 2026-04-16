import Foundation

/// Date-ordered bucket for the conversation list. The enum order is the display order.
enum ChatDateBucket: String, Sendable, Hashable, CaseIterable {
    case today
    case yesterday
    case thisWeek
    case earlier

    var title: String {
        switch self {
        case .today: "Today"
        case .yesterday: "Yesterday"
        case .thisWeek: "This week"
        case .earlier: "Earlier"
        }
    }
}

/// A section of conversations under one `ChatDateBucket`.
struct ConversationGroup: Sendable, Hashable, Identifiable {
    let bucket: ChatDateBucket
    let conversations: [Conversation]

    var id: ChatDateBucket { bucket }
}

/// Pure, testable grouping logic. Buckets are relative to `now` and use the user's current
/// calendar. Conversations inside each bucket keep the caller's supplied order (which the
/// repository hands back as "last message first").
nonisolated enum ConversationGrouping {
    static func group(
        _ conversations: [Conversation],
        now: Date,
        calendar: Calendar = .current
    ) -> [ConversationGroup] {
        var buckets: [ChatDateBucket: [Conversation]] = [:]
        for conversation in conversations {
            let bucket = bucketForDate(conversation.lastMessageAt, now: now, calendar: calendar)
            buckets[bucket, default: []].append(conversation)
        }
        return ChatDateBucket.allCases.compactMap { bucket in
            guard let items = buckets[bucket], !items.isEmpty else { return nil }
            return ConversationGroup(bucket: bucket, conversations: items)
        }
    }

    static func bucketForDate(_ date: Date, now: Date, calendar: Calendar = .current) -> ChatDateBucket {
        if calendar.isDateInToday(date) { return .today }
        if calendar.isDateInYesterday(date) { return .yesterday }
        let startOfToday = calendar.startOfDay(for: now)
        if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday),
           date >= sevenDaysAgo {
            return .thisWeek
        }
        return .earlier
    }
}
