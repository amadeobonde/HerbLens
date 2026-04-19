import Foundation
import UIKit

/// State machine for the Scan flow. Enum drives `ScanView` so unreachable combinations
/// stay unrepresentable.
@MainActor
public enum ScanState: Equatable {
    case idle
    case permissionDenied(PermissionSource)
    case capturing
    case identifying(UIImage)
    case result(ScanResult)
    case failed(ScanDisplayError)

    public var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    public static func == (lhs: ScanState, rhs: ScanState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case let (.permissionDenied(a), .permissionDenied(b)):
            return a == b
        case (.capturing, .capturing):
            return true
        case let (.identifying(a), .identifying(b)):
            return a === b
        case let (.result(a), .result(b)):
            return a == b
        case let (.failed(a), .failed(b)):
            return a == b
        default:
            return false
        }
    }

    public enum PermissionSource: Equatable, Sendable {
        case camera
        case photoLibrary
    }
}
