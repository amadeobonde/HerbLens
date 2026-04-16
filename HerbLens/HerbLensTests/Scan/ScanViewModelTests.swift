import Foundation
import Testing
import UIKit
@testable import HerbLens

/// Behavior tests for the Scan view-model. Exercises the happy path (high-confidence),
/// the low-confidence branch (chips required to pick a candidate), and the paywall
/// trigger (`ScanError.quotaExceeded` from the repository). No network, no camera.
@Suite("ScanViewModel")
@MainActor
struct ScanViewModelTests {
    private static let onePixel: UIImage = {
        UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }()

    @Test("high-confidence identify populates selected plant with top match")
    func highConfidencePopulatesSelected() async {
        let vm = ScanViewModel(
            scans: StubScans(result: .highConfidence),
            plants: MockServices.Plants(),
            subscriptions: FreeSubscriptions(),
            imageProcessor: PassthroughProcessor(),
            userID: SampleData.userID
        )
        await vm.submit(image: Self.onePixel)
        guard case .result(let result) = vm.state else {
            Issue.record("expected .result, got \(vm.state)")
            return
        }
        #expect(result.identification.confidence == 0.94)
        #expect(result.selectedPlant?.id == SampleData.chamomile.id)
        #expect(result.isLowConfidence == false)
    }

    @Test("low-confidence leaves selected nil until pickCandidate is called")
    func lowConfidenceRequiresPick() async {
        let vm = ScanViewModel(
            scans: StubScans(result: .lowConfidence),
            plants: MockServices.Plants(),
            subscriptions: FreeSubscriptions(),
            imageProcessor: PassthroughProcessor(),
            userID: SampleData.userID
        )
        await vm.submit(image: Self.onePixel)

        guard case .result(let result) = vm.state else {
            Issue.record("expected .result")
            return
        }
        #expect(result.selectedPlant == nil)
        #expect(result.isLowConfidence)

        vm.pickCandidate(SampleData.peppermint)

        guard case .result(let updated) = vm.state else {
            Issue.record("expected .result after pick")
            return
        }
        #expect(updated.selectedPlant?.id == SampleData.peppermint.id)
    }

    @Test("quota-exceeded transitions to paywall state and never calls plants")
    func quotaExceededTriggersPaywallState() async {
        let overQuota = MockServices.ScansOverQuota()
        let plants = CountingPlants()
        let vm = ScanViewModel(
            scans: overQuota,
            plants: plants,
            subscriptions: FreeSubscriptions(),
            imageProcessor: PassthroughProcessor(),
            userID: SampleData.userID
        )
        await vm.submit(image: Self.onePixel)
        guard case .quotaExceeded(let limit) = vm.state else {
            Issue.record("expected .quotaExceeded, got \(vm.state)")
            return
        }
        #expect(limit == 3)
        #expect(plants.searchCount == 0)
    }

    @Test("save constructs a Scan echoing the selected plant + confidence")
    func saveEchoesSelection() async {
        let vm = ScanViewModel(
            scans: StubScans(result: .highConfidence),
            plants: MockServices.Plants(),
            subscriptions: FreeSubscriptions(),
            imageProcessor: PassthroughProcessor(),
            userID: SampleData.userID
        )
        await vm.submit(image: Self.onePixel)
        let saved = await vm.save()
        #expect(saved != nil)
        #expect(saved?.identifiedPlantId == SampleData.chamomile.id)
        #expect(saved?.confidenceScore == 0.94)
        if case .idle = vm.state {} else {
            Issue.record("expected .idle after save; got \(vm.state)")
        }
    }

    @Test("free-tier remaining chip counts down after each successful scan")
    func remainingCountsDown() async {
        let vm = ScanViewModel(
            scans: StubScans(result: .highConfidence),
            plants: MockServices.Plants(),
            subscriptions: FreeSubscriptions(),
            imageProcessor: PassthroughProcessor(),
            userID: SampleData.userID
        )
        await vm.onAppear()
        if case .idle(let remaining) = vm.state {
            #expect(remaining == 3)
        } else {
            Issue.record("expected .idle after onAppear")
        }
        await vm.submit(image: Self.onePixel)
        _ = await vm.save()
        if case .idle(let remaining) = vm.state {
            #expect(remaining == 2)
        } else {
            Issue.record("expected .idle after save")
        }
    }
}

// MARK: - Test doubles

private nonisolated struct PassthroughProcessor: ImageProcessing {
    nonisolated init() {}
    func prepare(_ image: UIImage) async throws -> Data {
        image.pngData() ?? Data([0xFF])
    }
}

private nonisolated struct StubScans: ScansRepository {
    enum Mode: Sendable { case highConfidence, lowConfidence }
    let mode: Mode

    nonisolated init(result: Mode) { self.mode = result }

    func identify(imageData: Data) async throws -> IdentifyResult {
        switch mode {
        case .highConfidence:
            return IdentifyResult(
                plantID: SampleData.chamomile.id,
                confidence: 0.94,
                suggestedMatches: [SampleData.chamomile, SampleData.peppermint],
                rawIdentification: "Chamomile"
            )
        case .lowConfidence:
            return IdentifyResult(
                plantID: nil,
                confidence: 0.55,
                suggestedMatches: [SampleData.chamomile, SampleData.peppermint, SampleData.lavender],
                rawIdentification: "Not sure"
            )
        }
    }

    func save(_ scan: Scan) async throws -> Scan { scan }
    func list(userID: String, sort: ScanSort, filter: ScanFilter) async throws -> [Scan] { [] }
    func toggleFavorite(scanID: String) async throws {}
    func delete(scanID: String) async throws {}
}

private final class CountingPlants: PlantsRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var _searchCount = 0
    var searchCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _searchCount
    }

    nonisolated init() {}

    func featured() async throws -> [Plant] { [] }
    func plant(id: String) async throws -> Plant { SampleData.chamomile }
    func search(query: String) async throws -> [Plant] {
        lock.lock(); _searchCount += 1; lock.unlock()
        return []
    }
    func healthScore(for plantID: String, userID: String) async throws -> HealthScore {
        SampleData.chamomile.healthScore
    }
    func highlightCollections() async throws -> [HighlightCollection] { [] }
}

private nonisolated struct FreeSubscriptions: SubscriptionService {
    nonisolated init() {}
    func currentTier() async -> SubscriptionTier { .free }
    func offerings() async throws -> [Offering] { [] }
    func purchase(packageID: String) async throws -> SubscriptionTier { .free }
    func restore() async throws -> SubscriptionTier { .free }
}
