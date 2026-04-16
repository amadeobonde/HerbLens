import Foundation

/// In-memory mock conformances for every service protocol. Satisfies `AppDependencies.mock`
/// and SwiftUI `#Preview` usage. Instance 2 supplies the Supabase-backed live versions.
nonisolated enum MockServices {
    // MARK: - Auth

    struct Auth: AuthService {
        var currentUserID: String? { get async { SampleData.userID } }

        func signUp(email: String, password: String) async throws -> UserProfile { SampleData.userProfile }
        func signIn(email: String, password: String) async throws -> UserProfile { SampleData.userProfile }
        func signOut() async throws {}
        func sendMagicLink(email: String) async throws {}
    }

    // MARK: - Plants

    struct Plants: PlantsRepository {
        func featured() async throws -> [Plant] { [SampleData.chamomile] }

        func plant(id: String) async throws -> Plant {
            guard id == SampleData.chamomile.id else { throw MockError.notFound }
            return SampleData.chamomile
        }

        func search(query: String) async throws -> [Plant] {
            let q = query.lowercased()
            return [SampleData.chamomile].filter { $0.commonName.lowercased().contains(q) }
        }

        func healthScore(for plantID: String, userID: String) async throws -> HealthScore {
            SampleData.chamomile.healthScore
        }

        func highlightCollections() async throws -> [HighlightCollection] {
            [SampleData.highlightCollection]
        }
    }

    // MARK: - Scans

    actor Scans: ScansRepository {
        private var stored: [Scan] = [SampleData.scan]

        func identify(imageData: Data) async throws -> IdentifyResult {
            IdentifyResult(
                plantID: SampleData.chamomile.id,
                confidence: 0.94,
                suggestedMatches: [SampleData.chamomile],
                rawIdentification: "chamomile"
            )
        }

        func save(_ scan: Scan) async throws -> Scan {
            stored.append(scan)
            return scan
        }

        func list(userID: String, sort: ScanSort, filter: ScanFilter) async throws -> [Scan] {
            stored
        }

        func toggleFavorite(scanID: String) async throws {
            guard let index = stored.firstIndex(where: { $0.id == scanID }) else { return }
            let existing = stored[index]
            stored[index] = Scan(
                id: existing.id,
                userId: existing.userId,
                photoUrl: existing.photoUrl,
                scannedAt: existing.scannedAt,
                identifiedPlantId: existing.identifiedPlantId,
                confidenceScore: existing.confidenceScore,
                userNotes: existing.userNotes,
                isFavorited: !existing.isFavorited,
                healthScoreAtScan: existing.healthScoreAtScan,
                accessTier: existing.accessTier
            )
        }

        func delete(scanID: String) async throws {
            stored.removeAll { $0.id == scanID }
        }
    }

    // MARK: - Chat

    struct Chat: ChatRepository {
        func conversations(userID: String) async throws -> [Conversation] {
            [SampleData.conversation]
        }

        func messages(conversationID: String) async throws -> [Message] {
            SampleData.conversation.messages
        }

        func startConversation(userID: String, contextPlantID: String?) async throws -> Conversation {
            Conversation(
                id: UUID().uuidString,
                userId: userID,
                startedAt: .now,
                lastMessageAt: .now,
                contextPlantId: contextPlantID,
                messages: []
            )
        }

        func send(message: String, to conversationID: String) -> AsyncThrowingStream<String, Error> {
            AsyncThrowingStream { continuation in
                let reply = "That's a good question about herbal remedies. This is mock output."
                Task {
                    for word in reply.split(separator: " ") {
                        continuation.yield(String(word) + " ")
                        try? await Task.sleep(nanoseconds: 50_000_000)
                    }
                    continuation.finish()
                }
            }
        }
    }

    // MARK: - Subscriptions

    actor Subscriptions: SubscriptionService {
        private var tier: SubscriptionTier = .free

        func currentTier() async -> SubscriptionTier { tier }
        func offerings() async throws -> [Offering] { SampleData.offerings }

        func purchase(packageID: String) async throws -> SubscriptionTier {
            tier = .premium
            return tier
        }

        func restore() async throws -> SubscriptionTier { tier }
    }

    // MARK: - HealthProfile

    actor HealthProfileRepo: HealthProfileRepository {
        private var stored: HealthProfile = SampleData.healthProfile

        func load(userID: String) async throws -> HealthProfile { stored }
        func save(_ profile: HealthProfile) async throws { stored = profile }
    }

    // MARK: - Errors

    enum MockError: Error {
        case notFound
    }
}
