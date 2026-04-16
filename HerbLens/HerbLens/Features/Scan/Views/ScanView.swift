import SwiftUI

/// Feature entry point. Drives the state machine and dispatches between idle → loading
/// → result / quota / error screens. Accepts closures so it hands off to the Vault
/// (Instance 8) and Paywall (Instance 10) without importing them.
public struct ScanView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: ScanViewModel?

    public let onOpenVault: (() -> Void)?
    public let onPaywall: () -> Void

    public init(onOpenVault: (() -> Void)? = nil, onPaywall: @escaping () -> Void) {
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
        case .idle(let remaining):
            ScanIdleView(tier: vm.tier, remaining: remaining) { image in
                Task { await vm.submit(image: image) }
            }
        case .capturing, .identifying:
            ScanLoadingView()
        case .result(let result):
            ScanResultView(
                result: result,
                tier: vm.tier,
                onSave: {
                    Task { _ = await vm.save() }
                },
                onScanAnother: { vm.reset() },
                onPickCandidate: { vm.pickCandidate($0) },
                onOpenVault: onOpenVault
            )
        case .quotaExceeded(let limit):
            QuotaReachedView(
                limit: limit,
                onPaywall: onPaywall,
                onDismiss: { vm.reset() }
            )
        case .failed(let error):
            ScanErrorOverlay(error: error, onDismiss: { vm.dismissError() })
        case .permissionDenied:
            ScanIdleView(tier: vm.tier, remaining: nil) { image in
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

private struct ScanErrorOverlay: View {
    let error: ScanDisplayError
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.Color.ember)
                Text(error.title)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text(error.message)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
                Button(error.retriable ? "Try again" : "OK", action: onDismiss)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.bone)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Capsule().fill(Theme.Color.forest))
            }
            .padding(Theme.Spacing.xl)
        }
    }
}
