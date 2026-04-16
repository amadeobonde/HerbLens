import Foundation
import Observation
import UIKit

/// Drives the scan flow: permission → capture → compress → identify → save. Lives on the
/// main actor because it publishes UI state. Services are injected so the whole pipeline
/// runs against `MockServices` in previews and `SupabaseScansRepository` at runtime.
@Observable
@MainActor
public final class ScanViewModel {
    public private(set) var state: ScanState = .idle(remaining: nil)
    public private(set) var tier: SubscriptionTier = .free

    private let scans: any ScansRepository
    private let plants: any PlantsRepository
    private let subscriptions: any SubscriptionService
    private let imageProcessor: any ImageProcessing
    private let userID: String?

    /// Local counter we use as a stop-gap until `ScansRepository` exposes a
    /// `remainingToday` query. Incremented on every successful identify so the idle chip
    /// counts down without a network round-trip per screen.
    private var scansUsedThisSessionFree: Int = 0

    public init(
        scans: any ScansRepository,
        plants: any PlantsRepository,
        subscriptions: any SubscriptionService,
        imageProcessor: any ImageProcessing = DefaultImageProcessor(),
        userID: String? = nil
    ) {
        self.scans = scans
        self.plants = plants
        self.subscriptions = subscriptions
        self.imageProcessor = imageProcessor
        self.userID = userID
    }

    public func onAppear() async {
        let currentTier = await subscriptions.currentTier()
        self.tier = currentTier
        self.state = .idle(remaining: remainingForIdle())
    }

    public func refreshTier() async {
        let currentTier = await subscriptions.currentTier()
        self.tier = currentTier
        if case .idle = state {
            state = .idle(remaining: remainingForIdle())
        }
    }

    public func submit(image: UIImage) async {
        state = .identifying(image)
        do {
            let data = try await imageProcessor.prepare(image)
            let identification = try await scans.identify(imageData: data)
            let result = ScanResult(image: image, identification: identification)
            state = .result(result)
            if tier == .free {
                scansUsedThisSessionFree += 1
            }
            ScanHaptics.success(tier: tier)
        } catch let error as ScanError {
            switch error {
            case .quotaExceeded(let limit):
                state = .quotaExceeded(limit: limit)
            }
        } catch {
            state = .failed(.from(error))
        }
    }

    public func pickCandidate(_ plant: Plant) {
        guard case .result(var result) = state else { return }
        result.selectedPlant = plant
        state = .result(result)
    }

    public func save() async -> Scan? {
        guard case .result(let result) = state, let plant = result.selectedPlant else {
            return nil
        }
        let scan = Scan(
            id: "",
            userId: userID ?? "",
            photoUrl: "",
            scannedAt: Date(),
            identifiedPlantId: plant.id,
            confidenceScore: result.identification.confidence,
            userNotes: nil,
            isFavorited: false,
            healthScoreAtScan: plant.healthScore.overallScore,
            accessTier: plant.accessTier
        )
        do {
            let persisted = try await scans.save(scan)
            resetToIdle()
            return persisted
        } catch let error as ScanError {
            switch error {
            case .quotaExceeded(let limit):
                state = .quotaExceeded(limit: limit)
            }
            return nil
        } catch {
            state = .failed(.from(error))
            return nil
        }
    }

    public func reset() {
        resetToIdle()
    }

    public func dismissError() {
        resetToIdle()
    }

    private func resetToIdle() {
        state = .idle(remaining: remainingForIdle())
    }

    private func remainingForIdle() -> Int? {
        guard tier == .free else { return nil }
        return max(0, freeLimit - scansUsedThisSessionFree)
    }

    /// Kept aligned with `SupabaseScansRepository.dailyFreeLimit` (3). Swap to the real
    /// limit when the pending `remainingToday` helper lands.
    public static let freeLimitFallback: Int = 3

    private var freeLimit: Int { Self.freeLimitFallback }
}
