import Foundation
@testable import HerbLens

/// Minimal `ScansRepository` stub used by `VaultViewModelTests` — the VM calls
/// `toggleFavorite` and `delete` during interactions, and we want to verify the VM's
/// own state transitions without dragging in `MockServices.Scans`'s seeded data.
/// Records every call and can be primed to throw for error-path tests.
actor TestScansRepo: ScansRepository {
    enum Stub: Error { case forced }

    private(set) var toggleCalls: [String] = []
    private(set) var deleteCalls: [String] = []
    private var shouldThrow: Bool = false

    func setThrowing(_ value: Bool) {
        shouldThrow = value
    }

    func identify(imageData: Data) async throws -> IdentifyResult {
        IdentifyResult(plantID: nil, confidence: 0, suggestedMatches: [], rawIdentification: nil)
    }

    func save(_ scan: Scan) async throws -> Scan { scan }

    func list(userID: String, sort: ScanSort, filter: ScanFilter) async throws -> [Scan] { [] }

    func toggleFavorite(scanID: String) async throws {
        toggleCalls.append(scanID)
        if shouldThrow { throw Stub.forced }
    }

    func delete(scanID: String) async throws {
        deleteCalls.append(scanID)
        if shouldThrow { throw Stub.forced }
    }
}
