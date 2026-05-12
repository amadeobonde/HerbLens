import SwiftUI

/// Feature entry point. Drives the state machine and dispatches between idle → loading
/// → result / quota / error screens. Accepts closures so it hands off to the Vault
/// (Instance 8) and Paywall (Instance 10) without importing them.
public struct ScanView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: ScanViewModel?

    public let onOpenVault: (@Sendable () -> Void)?
    public let onPaywall: @Sendable () -> Void

    public init(onOpenVault: (@Sendable () -> Void)? = nil, onPaywall: @escaping @Sendable () -> Void) {
        self.onOpenVault = onOpenVault
        self.onPaywall = onPaywall
    }

    public var body: some View {
        Group {
            if let viewModel {
                content(for: viewModel)
            } else {
                Theme.Color.background.ignoresSafeArea()
                    .task { await bootstrap() }
            }
        }
    }

    @ViewBuilder
    private func content(for vm: ScanViewModel) -> some View {
        switch vm.state {
        case .idle:
            ScanIdleView(tier: vm.tier) { image in
                Task { await vm.submit(image: image) }
            }
        case .capturing:
            ScanLoadingView()
        case .identifying(let image):
            ScanLoadingView(capturedImage: image)
        case .result(let result):
            ScanResultView(
                result: result,
                tier: vm.tier,
                onSave: {
                    Task { _ = await vm.save() }
                },
                onScanAnother: { Task { @MainActor in vm.reset() } },
                onPickCandidate: { candidate in Task { @MainActor in vm.pickCandidate(candidate) } },
                onOpenVault: onOpenVault
            )
        case .failed(let error):
            ScanErrorView(error: error, onDismiss: { Task { @MainActor in vm.dismissError() } })
        case .permissionDenied:
            ScanIdleView(tier: vm.tier) { image in
                Task { await vm.submit(image: image) }
            }
        }
    }

    private func bootstrap() async {
        let uid = await dependencies.auth.currentUserID
        let vm = ScanViewModel(
            scans: dependencies.scans,
            plants: dependencies.plants,
            subscriptions: dependencies.subscriptions,
            userID: uid
        )
        viewModel = vm
        await vm.onAppear()
    }
}
