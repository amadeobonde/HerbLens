import Foundation
import UIKit

/// Post-identify snapshot. Carries the user's image so the result card can show what
/// they captured next to the catalog match, and lets them pick a different suggestion
/// when confidence is low.
@MainActor
public struct ScanResult: Equatable {
    public static let lowConfidenceThreshold: Double = 0.75

    public let image: UIImage
    public let identification: IdentifyResult
    public var selectedPlant: Plant?

    public init(image: UIImage, identification: IdentifyResult) {
        self.image = image
        self.identification = identification
        if identification.confidence >= Self.lowConfidenceThreshold {
            self.selectedPlant = identification.suggestedMatches.first
        } else {
            self.selectedPlant = nil
        }
    }

    public var isLowConfidence: Bool {
        identification.confidence < Self.lowConfidenceThreshold
    }
}
