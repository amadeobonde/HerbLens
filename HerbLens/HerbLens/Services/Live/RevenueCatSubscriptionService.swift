import Foundation
@preconcurrency import RevenueCat

/// Thin wrapper around `Purchases.shared` that exposes only the subset of RevenueCat the
/// app needs. The `PurchasesAdapter` protocol lets tests swap in a fake without pulling in
/// the full RevenueCat SDK surface — otherwise mocking is painful (sealed classes,
/// StoreKit state, etc).
public final class RevenueCatSubscriptionService: SubscriptionService, @unchecked Sendable {
    public nonisolated static let premiumEntitlement = "premium"

    private let adapter: any PurchasesAdapter

    public nonisolated init(adapter: (any PurchasesAdapter)? = nil) {
        self.adapter = adapter ?? RevenueCatPurchasesAdapter(apiKey: AppConfig.revenueCatKey)
    }

    public nonisolated func currentTier() async -> SubscriptionTier {
        do {
            let info = try await adapter.customerInfo()
            return info.isPremiumActive ? .premium : .free
        } catch {
            return .free
        }
    }

    public nonisolated func offerings() async throws -> [Offering] {
        try await adapter.fetchOfferings()
    }

    public nonisolated func purchase(packageID: String) async throws -> SubscriptionTier {
        let info = try await adapter.purchase(packageID: packageID)
        return info.isPremiumActive ? .premium : .free
    }

    public nonisolated func restore() async throws -> SubscriptionTier {
        let info = try await adapter.restore()
        return info.isPremiumActive ? .premium : .free
    }
}

// MARK: - Adapter seam (testable)

/// Narrow surface we need from RevenueCat. `RevenueCatPurchasesAdapter` is the production
/// implementation; tests supply their own conforming type.
public protocol PurchasesAdapter: Sendable {
    func customerInfo() async throws -> CustomerInfoSnapshot
    func fetchOfferings() async throws -> [Offering]
    func purchase(packageID: String) async throws -> CustomerInfoSnapshot
    func restore() async throws -> CustomerInfoSnapshot
}

/// Just enough of RC's CustomerInfo to answer "are we premium?".
public struct CustomerInfoSnapshot: Sendable, Equatable {
    public let isPremiumActive: Bool

    public nonisolated init(isPremiumActive: Bool) {
        self.isPremiumActive = isPremiumActive
    }
}

/// Production adapter — boots `Purchases` once and maps its types onto our thin protocol.
public final class RevenueCatPurchasesAdapter: PurchasesAdapter, @unchecked Sendable {
    public nonisolated init(apiKey: String) {
        if !Purchases.isConfigured {
            Purchases.configure(withAPIKey: apiKey)
        }
    }

    public func customerInfo() async throws -> CustomerInfoSnapshot {
        let info = try await Purchases.shared.customerInfo()
        return snapshot(from: info)
    }

    public func fetchOfferings() async throws -> [Offering] {
        let rcOfferings = try await Purchases.shared.offerings()
        guard let current = rcOfferings.current else { return [] }
        return current.availablePackages.map { Self.toDomain($0) }
    }

    public func purchase(packageID: String) async throws -> CustomerInfoSnapshot {
        let offerings = try await Purchases.shared.offerings()
        guard let package = offerings.current?.availablePackages.first(where: { $0.identifier == packageID }) else {
            throw ServiceError.decodingFailed("package \(packageID) not found in current offering")
        }
        let result = try await Purchases.shared.purchase(package: package)
        return snapshot(from: result.customerInfo)
    }

    public func restore() async throws -> CustomerInfoSnapshot {
        let info = try await Purchases.shared.restorePurchases()
        return snapshot(from: info)
    }

    private func snapshot(from info: CustomerInfo) -> CustomerInfoSnapshot {
        let entitlement = info.entitlements[RevenueCatSubscriptionService.premiumEntitlement]
        return CustomerInfoSnapshot(isPremiumActive: entitlement?.isActive == true)
    }

    static func toDomain(_ package: Package) -> Offering {
        Offering(
            id: package.offeringIdentifier,
            packageID: package.identifier,
            displayName: package.storeProduct.localizedTitle,
            priceString: package.storeProduct.localizedPriceString,
            tier: .premium,
            periodDescription: Self.periodDescription(for: package),
            trialDays: Self.trialDays(for: package)
        )
    }

    private static func periodDescription(for package: Package) -> String? {
        guard let unit = package.storeProduct.subscriptionPeriod?.unit,
              let value = package.storeProduct.subscriptionPeriod?.value
        else { return nil }
        switch unit {
        case .day: return "\(value) day\(value == 1 ? "" : "s")"
        case .week: return "\(value) week\(value == 1 ? "" : "s")"
        case .month: return "\(value) month\(value == 1 ? "" : "s")"
        case .year: return "\(value) year\(value == 1 ? "" : "s")"
        @unknown default: return nil
        }
    }

    private static func trialDays(for package: Package) -> Int? {
        guard let intro = package.storeProduct.introductoryDiscount,
              intro.paymentMode == .freeTrial else { return nil }
        return intro.subscriptionPeriod.unit == .day
            ? intro.subscriptionPeriod.value
            : intro.subscriptionPeriod.unit == .week ? intro.subscriptionPeriod.value * 7 : nil
    }
}
