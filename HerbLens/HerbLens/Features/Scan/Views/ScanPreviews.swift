import SwiftUI
import UIKit

#if DEBUG
private enum PreviewHelpers {
    static func bambooImage() -> UIImage {
        UIImage(named: "Scan/BambooCelebrating") ?? UIImage(systemName: "leaf")!
    }
}

#Preview("Idle — free user") {
    ScanIdleView(tier: .free, remaining: 3) { _ in }
}

#Preview("Idle — premium") {
    ScanIdleView(tier: .premium, remaining: nil) { _ in }
}

#Preview("Remaining chip — free / 2 left") {
    ScanRemainingChip(tier: .free, remaining: 2).padding()
}

#Preview("Remaining chip — premium") {
    ScanRemainingChip(tier: .premium, remaining: nil).padding()
}

#Preview("Result — high confidence") {
    let plant = SampleData.chamomile
    let identification = IdentifyResult(
        plantID: plant.id,
        confidence: 0.94,
        suggestedMatches: [plant, SampleData.peppermint],
        rawIdentification: "Chamomile (Matricaria chamomilla)"
    )
    return ScanResultView(
        result: ScanResult(image: PreviewHelpers.bambooImage(), identification: identification),
        tier: .free,
        onSave: {},
        onScanAnother: {},
        onPickCandidate: { _ in },
        onOpenVault: nil
    )
}

#Preview("Result — low confidence") {
    let identification = IdentifyResult(
        plantID: nil,
        confidence: 0.55,
        suggestedMatches: [SampleData.chamomile, SampleData.peppermint, SampleData.lavender],
        rawIdentification: "Could be a few things — take a closer look."
    )
    return ScanResultView(
        result: ScanResult(image: PreviewHelpers.bambooImage(), identification: identification),
        tier: .free,
        onSave: {},
        onScanAnother: {},
        onPickCandidate: { _ in },
        onOpenVault: nil
    )
}

#Preview("Quota reached") {
    QuotaReachedView(limit: 3, onPaywall: {}, onDismiss: {})
}

#Preview("Loading") {
    ScanLoadingView()
}
#endif
