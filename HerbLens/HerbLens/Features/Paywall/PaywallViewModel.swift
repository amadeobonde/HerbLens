import Foundation
import Observation

/// Drives the Paywall screen. Loads offerings via `SubscriptionService.offerings()`,
/// tracks the currently-selected package, and coordinates purchase + restore flows.
///
/// The view pushes the success overlay by observing `purchaseSucceeded` — the VM sets
/// it immediately after `purchase` or `restore` resolves to `.premium`, so the celebratory
/// animation can fire in parallel with `PaywallView.dismiss`.
@MainActor
@Observable
final class PaywallViewModel {
    // MARK: - Loaded data

    private(set) var offerings: [Offering] = []
    private(set) var tier: SubscriptionTier = .free

    // MARK: - UI state

    var selectedPackageID: String?
    private(set) var isLoadingOfferings: Bool = false
    private(set) var isPurchasing: Bool = false
    private(set) var isRestoring: Bool = false
    private(set) var errorMessage: String?
    private(set) var purchaseSucceeded: Bool = false

    // MARK: - Derived

    /// Monthly + yearly cards sorted so "Best value" yearly renders second. Falls back
    /// to the raw offering list order when we can't identify a yearly option.
    var sortedOfferings: [Offering] {
        guard !offerings.isEmpty else { return [] }
        let monthly = offerings.filter { $0.periodDescription?.localizedCaseInsensitiveContains("month") == true }
        let yearly = offerings.filter { $0.periodDescription?.localizedCaseInsensitiveContains("year") == true }
        guard !monthly.isEmpty && !yearly.isEmpty else { return offerings }
        let other = offerings.filter { !monthly.contains($0) && !yearly.contains($0) }
        return monthly + yearly + other
    }

    /// The offering currently highlighted for purchase. Defaults to the best-value yearly
    /// package once offerings have loaded so free-tier users see the deal we want to sell.
    var selectedOffering: Offering? {
        guard let id = selectedPackageID else { return nil }
        return offerings.first { $0.packageID == id }
    }

    /// Whether a specific offering should render the "Best value" badge. Yearly wins if
    /// we can find one; otherwise no badge (we never crown monthly).
    func isBestValue(_ offering: Offering) -> Bool {
        offering.periodDescription?.localizedCaseInsensitiveContains("year") == true
    }

    // MARK: - Intents

    func load(subscriptions: any SubscriptionService) async {
        isLoadingOfferings = true
        errorMessage = nil
        defer { isLoadingOfferings = false }

        do {
            async let loadedTier = subscriptions.currentTier()
            let loaded = try await subscriptions.offerings()
            offerings = loaded
            tier = await loadedTier
            preselectDefault()
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func purchase(packageID: String, subscriptions: any SubscriptionService) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            let newTier = try await subscriptions.purchase(packageID: packageID)
            tier = newTier
            if newTier == .premium {
                purchaseSucceeded = true
            }
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func restore(subscriptions: any SubscriptionService) async {
        guard !isRestoring else { return }
        isRestoring = true
        errorMessage = nil
        defer { isRestoring = false }

        do {
            let newTier = try await subscriptions.restore()
            tier = newTier
            if newTier == .premium {
                purchaseSucceeded = true
            } else {
                errorMessage = "No active subscription found on this Apple ID."
            }
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    /// Clears the success flag so the overlay can dismiss. Called by the view's animation
    /// completion callback.
    func acknowledgeSuccess() {
        purchaseSucceeded = false
    }

    // MARK: - Testing affordance

    /// Lets tests pre-seed offerings + tier without a live `load()` round-trip. Mirrors
    /// the `apply(scans:plants:tier:)` escape hatch in `VaultViewModel`.
    func apply(offerings: [Offering], tier: SubscriptionTier) {
        self.offerings = offerings
        self.tier = tier
        preselectDefault()
    }

    // MARK: - Private

    private func preselectDefault() {
        if selectedPackageID == nil || offerings.first(where: { $0.packageID == selectedPackageID }) == nil {
            selectedPackageID = sortedOfferings.first(where: isBestValue)?.packageID
                ?? sortedOfferings.first?.packageID
        }
    }

    private func friendlyMessage(for error: Error) -> String {
        if let serviceError = error as? ServiceError {
            switch serviceError {
            case .unauthenticated:
                return "Please sign in to manage your subscription."
            case .httpStatus(let code, _):
                return "Couldn't reach the store (status \(code)). Try again."
            case .decodingFailed:
                return "Store response looked off — try again in a moment."
            case .malformedURL:
                return "Couldn't reach the store. Try again."
            }
        }
        return "Something went wrong. Try again."
    }
}
