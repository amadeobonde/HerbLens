import Foundation

public protocol ScansRepository: Sendable {
    func identify(imageData: Data) async throws -> IdentifyResult
    func save(_ scan: Scan) async throws -> Scan
    func list(userID: String, sort: ScanSort, filter: ScanFilter) async throws -> [Scan]
    func toggleFavorite(scanID: String) async throws
    func delete(scanID: String) async throws
}
