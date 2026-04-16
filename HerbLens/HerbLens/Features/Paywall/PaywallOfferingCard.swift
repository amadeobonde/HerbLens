import SwiftUI

/// Two-column pricing layout. When both monthly and yearly offerings are present we
/// render side-by-side `GlassCard`s — yearly highlighted with a sage stroke and a
/// "Save XX%" sage chip to bias selection toward the better-value plan. When only one
/// offering is available (or the offerings can't be paired), fall back to a stack of
/// full-width `PaywallOfferingCard`s using the same selection contract.
struct PaywallPricingGrid: View {
    let offerings: [Offering]
    let selectedPackageID: String?
    let isBestValue: (Offering) -> Bool
    let onSelect: (Offering) -> Void

    var body: some View {
        let pair = pairedOfferings(in: offerings)

        if let pair {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                PaywallOfferingCard(
                    offering: pair.monthly,
                    isSelected: selectedPackageID == pair.monthly.packageID,
                    isBestValue: false,
                    savingsPercent: nil,
                    showPerMonthBreakdown: false
                ) { onSelect(pair.monthly) }

                PaywallOfferingCard(
                    offering: pair.yearly,
                    isSelected: selectedPackageID == pair.yearly.packageID,
                    isBestValue: true,
                    savingsPercent: savingsPercent(monthly: pair.monthly, yearly: pair.yearly),
                    showPerMonthBreakdown: true
                ) { onSelect(pair.yearly) }
            }
        } else {
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(offerings) { offering in
                    PaywallOfferingCard(
                        offering: offering,
                        isSelected: selectedPackageID == offering.packageID,
                        isBestValue: isBestValue(offering),
                        savingsPercent: nil,
                        showPerMonthBreakdown: false
                    ) { onSelect(offering) }
                }
            }
        }
    }

    private struct OfferingPair {
        let monthly: Offering
        let yearly: Offering
    }

    private func pairedOfferings(in offerings: [Offering]) -> OfferingPair? {
        let monthly = offerings.first { $0.periodDescription?.localizedCaseInsensitiveContains("month") == true }
        let yearly = offerings.first { $0.periodDescription?.localizedCaseInsensitiveContains("year") == true }
        guard let monthly, let yearly else { return nil }
        return OfferingPair(monthly: monthly, yearly: yearly)
    }

    private func savingsPercent(monthly: Offering, yearly: Offering) -> Int? {
        guard
            let monthlyPrice = monthly.parsedPrice,
            let annualPrice = yearly.parsedPrice,
            monthlyPrice > 0
        else { return nil }
        let yearlyPerMonth = annualPrice / 12.0
        let raw = (1 - yearlyPerMonth / monthlyPrice) * 100
        let rounded = Int(raw.rounded())
        return rounded > 0 ? rounded : nil
    }
}

/// Single-offering pricing card. Drop into `PaywallPricingGrid` for a 2-column layout
/// or stack vertically when only one offering exists. Yearly cards expose
/// `referenceMonthlyPrice` so the headline price renders as `price/mo` with a smaller
/// "billed yearly" caption beneath.
struct PaywallOfferingCard: View {
    let offering: Offering
    let isSelected: Bool
    let isBestValue: Bool
    /// When non-nil, render a "Save XX%" sage chip in the top-right corner.
    let savingsPercent: Int?
    /// When `true`, derive the headline price as `priceString / 12` (used for yearly
    /// offerings) and surface a "$XX billed yearly" caption. When `false`, render the raw
    /// `priceString` with the period description.
    let showPerMonthBreakdown: Bool
    let action: () -> Void

    init(
        offering: Offering,
        isSelected: Bool,
        isBestValue: Bool,
        savingsPercent: Int? = nil,
        showPerMonthBreakdown: Bool = false,
        action: @escaping () -> Void
    ) {
        self.offering = offering
        self.isSelected = isSelected
        self.isBestValue = isBestValue
        self.savingsPercent = savingsPercent
        self.showPerMonthBreakdown = showPerMonthBreakdown
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                GlassCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(offering.displayName)
                            .font(Theme.Font.caption.weight(.semibold))
                            .foregroundStyle(Theme.Color.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.6)

                        Text(headlinePrice)
                            .font(Theme.Font.title)
                            .foregroundStyle(Theme.Color.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        Text(headlineSuffix)
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.textSecondary)

                        if let billingCaption {
                            Text(billingCaption)
                                .font(Theme.Font.caption)
                                .foregroundStyle(Theme.Color.textSecondary.opacity(0.85))
                                .padding(.top, Theme.Spacing.xxs)
                        }

                        if let trial = offering.trialDays, trial > 0 {
                            trialPill(days: trial)
                                .padding(.top, Theme.Spacing.xs)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                )

                if let savings = savingsPercent {
                    savingsChip(savings)
                        .padding(Theme.Spacing.xs)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Pricing presentation

    private var headlinePrice: String {
        if let monthly = referencedMonthlyPriceString {
            return monthly
        }
        return offering.priceString
    }

    private var headlineSuffix: String {
        if referencedMonthlyPriceString != nil {
            return "per month"
        }
        if let period = offering.periodDescription {
            return period
        }
        return ""
    }

    private var billingCaption: String? {
        guard referencedMonthlyPriceString != nil else { return nil }
        return "\(offering.priceString) billed yearly"
    }

    /// `nil` unless we can derive a per-month price (yearly card with a known annual price).
    private var referencedMonthlyPriceString: String? {
        guard
            showPerMonthBreakdown,
            let annual = offering.parsedPrice,
            annual > 0
        else { return nil }
        let perMonth = annual / 12.0
        return Self.priceFormatter.string(from: NSNumber(value: perMonth)) ?? String(format: "$%.2f", perMonth)
    }

    private static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f
    }()

    // MARK: - Decorations

    private var strokeColor: Color {
        if isSelected { return Theme.Color.forest }
        if isBestValue { return Theme.Color.sage }
        return Theme.Color.sage.opacity(0.25)
    }

    private var strokeWidth: CGFloat {
        if isSelected { return 2 }
        if isBestValue { return 1.5 }
        return 1
    }

    private func savingsChip(_ percent: Int) -> some View {
        Text("Save \(percent)%")
            .font(Theme.Font.caption.weight(.semibold))
            .foregroundStyle(Theme.Color.bone)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(Theme.Color.sage)
            )
    }

    private func trialPill(days: Int) -> some View {
        Text("\(days)-day free trial")
            .font(Theme.Font.caption.weight(.semibold))
            .foregroundStyle(Theme.Color.forest)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(Theme.Color.sage.opacity(0.25))
            )
    }

    private var accessibilityLabel: String {
        var parts: [String] = [offering.displayName, headlinePrice]
        if !headlineSuffix.isEmpty { parts.append(headlineSuffix) }
        if let billingCaption { parts.append(billingCaption) }
        if let savings = savingsPercent { parts.append("save \(savings) percent") }
        if let days = offering.trialDays, days > 0 { parts.append("\(days) day free trial") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Offering helpers

private extension Offering {
    /// Best-effort numeric extraction of the price for arithmetic. Returns nil for prices
    /// the formatter can't parse (e.g. localized non-Latin numerals); callers fall back to
    /// the raw `priceString` in that case.
    var parsedPrice: Double? {
        let trimmed = priceString
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let number = Self.parser.number(from: trimmed) {
            return number.doubleValue
        }
        // Fallback: strip every non-numeric / non-dot character and try Double.
        let stripped = trimmed.unicodeScalars.filter { CharacterSet(charactersIn: "0123456789.").contains($0) }
        return Double(String(String.UnicodeScalarView(stripped)))
    }

    static let parser: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f
    }()
}
