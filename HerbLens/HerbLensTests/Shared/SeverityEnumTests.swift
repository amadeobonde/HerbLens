import Foundation
import Testing
@testable import HerbLens

@Suite("Severity & enum rawValues")
struct SeverityEnumTests {
    private let decoder = JSONDecoder()

    @Test("Severity decodes the three canonical values",
          arguments: [("\"low\"", Severity.low), ("\"moderate\"", .moderate), ("\"high\"", .high)])
    func severityDecode(json: String, expected: Severity) throws {
        let value = try decoder.decode(Severity.self, from: Data(json.utf8))
        #expect(value == expected)
    }

    @Test("Severity rejects unknown string")
    func severityRejectsUnknown() {
        let data = Data("\"extreme\"".utf8)
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(Severity.self, from: data)
        }
    }

    @Test("WarningType maps snake_case medication_interaction")
    func warningTypeSnakeCase() throws {
        let value = try decoder.decode(WarningType.self, from: Data("\"medication_interaction\"".utf8))
        #expect(value == .medicationInteraction)
    }

    @Test("Climate enum covers the six canonical climates",
          arguments: ["tropical", "temperate", "arid", "subarctic", "mediterranean", "subtropical"])
    func climate(rawValue: String) throws {
        let value = try decoder.decode(Climate.self, from: Data("\"\(rawValue)\"".utf8))
        #expect(value.rawValue == rawValue)
    }

    @Test("SubscriptionTier and AccessTier decode")
    func tiers() throws {
        #expect(try decoder.decode(SubscriptionTier.self, from: Data("\"free\"".utf8)) == .free)
        #expect(try decoder.decode(SubscriptionTier.self, from: Data("\"premium\"".utf8)) == .premium)
        #expect(try decoder.decode(AccessTier.self, from: Data("\"free\"".utf8)) == .free)
        #expect(try decoder.decode(AccessTier.self, from: Data("\"premium\"".utf8)) == .premium)
    }
}
