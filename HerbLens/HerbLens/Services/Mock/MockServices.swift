import Foundation

/// In-memory mock conformances for every service protocol. Satisfies `AppDependencies.mock`
/// and SwiftUI `#Preview` usage. Instance 2 supplies the Supabase-backed live versions.
nonisolated enum MockServices {
    // MARK: - Auth

    nonisolated struct Auth: AuthService {
        nonisolated init() {}
        var currentUserID: String? { get async { SampleData.userID } }

        func signUp(email: String, password: String) async throws -> UserProfile { SampleData.userProfile }
        func signIn(email: String, password: String) async throws -> UserProfile { SampleData.userProfile }
        func signOut() async throws {}
        func sendMagicLink(email: String) async throws {}
        func verifyEmailOTP(email: String, token: String) async throws -> UserProfile { SampleData.userProfile }
        func completeOnboarding(userID: String) async throws {}
    }

    // MARK: - Plants

    nonisolated struct Plants: PlantsRepository {
        nonisolated init() {}
        func featured() async throws -> [Plant] {
            SampleData.plants.filter(\.featured)
        }

        func plant(id: String) async throws -> Plant {
            guard let plant = SampleData.plants.first(where: { $0.id == id }) else {
                throw MockError.notFound
            }
            return plant
        }

        func search(query: String) async throws -> [Plant] {
            let q = query.lowercased()
            guard !q.isEmpty else { return SampleData.plants }
            return SampleData.plants.filter { plant in
                plant.commonName.lowercased().contains(q)
                    || plant.alternateNames.contains(where: { $0.lowercased().contains(q) })
                    || plant.tags.contains(where: { $0.lowercased().contains(q) })
            }
        }

        func healthScore(for plantID: String, userID: String) async throws -> HealthScore {
            guard let plant = SampleData.plants.first(where: { $0.id == plantID }) else {
                throw MockError.notFound
            }
            return plant.healthScore
        }

        func highlightCollections() async throws -> [HighlightCollection] {
            SampleData.highlightCollections
        }
    }

    // MARK: - Scans

    /// Always-quota-exceeded variant so feature instances can preview the paywall trigger.
    /// Use in Previews by swapping `AppDependencies.mock.scans` with `MockServices.ScansOverQuota()`.
    nonisolated struct ScansOverQuota: ScansRepository {
        nonisolated init() {}
        func identify(imageData: Data) async throws -> IdentifyResult {
            throw ScanError.quotaExceeded(limit: 3)
        }
        func save(_ scan: Scan) async throws -> Scan { throw ScanError.quotaExceeded(limit: 3) }
        func list(userID: String, sort: ScanSort, filter: ScanFilter) async throws -> [Scan] { SampleData.scans }
        func toggleFavorite(scanID: String) async throws {}
        func delete(scanID: String) async throws {}
    }

    actor Scans: ScansRepository {
        init() {}
        private var stored: [Scan] = SampleData.scans

        func identify(imageData: Data) async throws -> IdentifyResult {
            IdentifyResult(
                plantID: SampleData.chamomile.id,
                confidence: 0.94,
                suggestedMatches: [SampleData.chamomile, SampleData.peppermint],
                rawIdentification: "Chamomile (Matricaria chamomilla) — 94% confidence."
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

    nonisolated struct Chat: ChatRepository {
        nonisolated init() {}

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

        nonisolated func send(message: String, to conversationID: String) -> AsyncThrowingStream<String, Error> {
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
        init() {}
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
        init() {}
        private var stored: HealthProfile = SampleData.healthProfile

        func load(userID: String) async throws -> HealthProfile { stored }
        func save(_ profile: HealthProfile) async throws { stored = profile }
    }

    // MARK: - Errors

    enum MockError: Error {
        case notFound
    }
}
