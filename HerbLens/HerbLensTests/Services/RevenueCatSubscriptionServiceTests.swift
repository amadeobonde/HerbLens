import Foundation
import Testing
@testable import HerbLens

@Suite("RevenueCat tier mapping")
struct RevenueCatSubscriptionServiceTests {
    @Test("premium entitlement → .premium")
    func premium() async {
        let adapter = StubAdapter(snapshot: .init(isPremiumActive: true))
        let svc = RevenueCatSubscriptionService(adapter: adapter)
        #expect(await svc.currentTier() == .premium)
    }

    @Test("no entitlement → .free")
    func free() async {
        let adapter = StubAdapter(snapshot: .init(isPremiumActive: false))
        let svc = RevenueCatSubscriptionService(adapter: adapter)
        #expect(await svc.currentTier() == .free)
    }

    @Test("adapter error defaults to .free (fail-safe)")
    func errorFallsBackToFree() async {
        let adapter = StubAdapter(snapshot: .init(isPremiumActive: true), error: NSError(domain: "rc", code: 1))
        let svc = RevenueCatSubscriptionService(adapter: adapter)
        // On error we prefer .free so a transient RC outage doesn't unlock premium content.
        #expect(await svc.currentTier() == .free)
    }

    @Test("purchase returns new tier based on resulting snapshot")
    func purchaseReturnsTier() async throws {
        let adapter = StubAdapter(
            snapshot: .init(isPremiumActive: false),
            purchaseSnapshot: .init(isPremiumActive: true)
        )
        let svc = RevenueCatSubscriptionService(adapter: adapter)
        let tier = try await svc.purchase(packageID: "any")
        #expect(tier == .premium)
    }

    @Test("restore surfaces adapter snapshot")
    func restore() async throws {
        let adapter = StubAdapter(
            snapshot: .init(isPremiumActive: false),
            restoreSnapshot: .init(isPremiumActive: true)
        )
        let svc = RevenueCatSubscriptionService(adapter: adapter)
        #expect(try await svc.restore() == .premium)
    }
}

private struct StubAdapter: PurchasesAdapter {
    let snapshot: CustomerInfoSnapshot
    var error: Error?
    var purchaseSnapshot: CustomerInfoSnapshot?
    var restoreSnapshot: CustomerInfoSnapshot?

    func customerInfo() async throws -> CustomerInfoSnapshot {
        if let error { throw error }
        return snapshot
    }
    func fetchOfferings() async throws -> [Offering] { [] }
    func purchase(packageID: String) async throws -> CustomerInfoSnapshot {
        purchaseSnapshot ?? snapshot
    }
    func restore() async throws -> CustomerInfoSnapshot {
        restoreSnapshot ?? snapshot
    }
}
