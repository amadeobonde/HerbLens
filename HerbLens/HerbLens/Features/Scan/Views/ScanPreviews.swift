import SwiftUI
import UIKit

#if DEBUG
private enum PreviewHelpers {
    static func bambooImage() -> UIImage {
        UIImage(named: "Scan/BambooCelebrating") ?? UIImage(systemName: "leaf")!
    }
}

#Preview("Idle — free user") {
    ScanIdleView(tier: .free) { _ in }
}

#Preview("Idle — premium") {
    ScanIdleView(tier: .premium) { _ in }
}

#Preview("Remaining chip — free") {
    ScanRemainingChip(tier: .free).padding()
}

#Preview("Remaining chip — premium") {
    ScanRemainingChip(tier: .premium).padding()
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

#Preview("Loading") {
    ScanLoadingView()
}

#Preview("Loading — with capture") {
    ScanLoadingView(capturedImage: PreviewHelpers.bambooImage())
}

#Preview("Error — retriable") {
    ScanErrorView(
        error: ScanDisplayError(
            title: "Identification failed",
            message: "We couldn't reach the identification service. Try another photo or check your connection.",
            retriable: true
        ),
        onDismiss: {}
    )
}
#endif
