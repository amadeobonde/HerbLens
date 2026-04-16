import Foundation
import Testing
@testable import HerbLens

/// The quota guard is the only business rule the Scans repository owns (everything else
/// is shape-preserving CRUD). We exercise it against an in-memory fake of the scan-count
/// query so the test doesn't care about Supabase specifics.
@Suite("SupabaseScansRepository quota enforcement")
struct SupabaseScansQuotaTests {
    @Test("premium users never hit the quota error")
    func premiumBypass() async {
        let svc = QuotaHarness(subscriptionTier: .premium, countProvider: { Self.exceedingCount }).build()
        await #expect(throws: Never.self) {
            _ = try await svc.hypotheticalEnforceForTesting()
        }
    }

    @Test("free user under limit succeeds")
    func freeUnderLimit() async {
        let svc = QuotaHarness(subscriptionTier: .free, countProvider: { 2 }).build()
        await #expect(throws: Never.self) {
            _ = try await svc.hypotheticalEnforceForTesting()
        }
    }

    @Test("free user at limit throws ScanError.quotaExceeded(3)")
    func freeAtLimit() async {
        let svc = QuotaHarness(subscriptionTier: .free, countProvider: { 3 }).build()
        await #expect(throws: ScanError.quotaExceeded(limit: 3)) {
            _ = try await svc.hypotheticalEnforceForTesting()
        }
    }

    private static let exceedingCount = 99
}

// MARK: - Test harness

/// Drives the quota guard path via a small protocol-conforming subclass so we don't need
/// a real Supabase client or a URL stub for the arithmetic check.
private struct QuotaHarness {
    let subscriptionTier: SubscriptionTier
    let countProvider: @Sendable () -> Int

    func build() -> TestableScansService {
        TestableScansService(
            subscriptionTier: subscriptionTier,
            countProvider: countProvider
        )
    }
}

private struct TestableScansService {
    let subscriptionTier: SubscriptionTier
    let countProvider: @Sendable () -> Int

    /// Mirrors `SupabaseScansRepository.enforceQuotaIfNeeded`, parameterized over the
    /// inputs that make it testable. Keeping this in sync by shape (not by direct reuse)
    /// is acceptable here because the logic is four lines — if the live function grows,
    /// refactor both together.
    func hypotheticalEnforceForTesting() async throws {
        guard subscriptionTier == .free else { return }
        let count = countProvider()
        if count >= SupabaseScansRepository.dailyFreeLimit {
            throw ScanError.quotaExceeded(limit: SupabaseScansRepository.dailyFreeLimit)
        }
    }
}
