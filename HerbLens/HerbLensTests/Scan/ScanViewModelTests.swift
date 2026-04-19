import Foundation
import Testing
import UIKit
@testable import HerbLens

/// Behavior tests for the Scan view-model. Exercises the happy path (high-confidence)
/// and the low-confidence branch (chips required to pick a candidate). No network, no camera.
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
        #expect(vm.state == .idle)
    }

    @Test("onAppear sets idle state")
    func onAppearSetsIdle() async {
        let vm = ScanViewModel(
            scans: StubScans(result: .highConfidence),
            plants: MockServices.Plants(),
            subscriptions: FreeSubscriptions(),
            imageProcessor: PassthroughProcessor(),
            userID: SampleData.userID
        )
        await vm.onAppear()
        #expect(vm.state == .idle)
        #expect(vm.tier == .free)
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

private nonisolated struct FreeSubscriptions: SubscriptionService {
    nonisolated init() {}
    func currentTier() async -> SubscriptionTier { .free }
    func offerings() async throws -> [Offering] { [] }
    func purchase(packageID: String) async throws -> SubscriptionTier { .free }
    func restore() async throws -> SubscriptionTier { .free }
}
