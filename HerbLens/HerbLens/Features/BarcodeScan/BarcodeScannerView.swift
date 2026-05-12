import SwiftUI
import Vision
import VisionKit

struct BarcodeScannerView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var scannedCode: String?
    @State private var lookupState: LookupState = .scanning

    private enum LookupState: Equatable {
        case scanning
        case lookingUp(String)
        case notFound(String)
        case found(PackagedProduct)
        case unsupported
    }
    
    // Injected service specifically for external catalog resolution
    private let barcodeService: any BarcodeService = OpenFoodFactsService()

    var body: some View {
        NavigationStack {
            Group {
                if DataScannerViewController.isSupported {
                    scannerContent
                } else {
                    unsupportedContent
                }
            }
            .background(Theme.Color.background.ignoresSafeArea())
            .navigationTitle("Scan barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: Theme.Icon.close)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var scannerContent: some View {
        switch lookupState {
        case .scanning:
            VStack(spacing: Theme.Spacing.lg) {
                DataScannerRepresentable { code in
                    guard lookupState == .scanning else { return }
                    lookupState = .lookingUp(code)
                    Task { await lookupBarcode(code) }
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)

                Text("Point at a barcode on herbal products")
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)

                Spacer()
            }

        case .lookingUp(let code):
            VStack(spacing: Theme.Spacing.md) {
                Spacer()
                ProgressView()
                    .tint(Theme.Color.sage)
                Text("Looking up \(code)…")
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textSecondary)
                Spacer()
            }

        case .notFound(let code):
            VStack(spacing: Theme.Spacing.md) {
                Spacer()
                Image(systemName: Theme.Icon.barcode)
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Color.sage.opacity(0.4))
                Text("Product not found")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("Barcode: \(code)")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)

                Button {
                    lookupState = .scanning
                } label: {
                    Text("Scan another")
                        .font(Theme.Font.callout.weight(.semibold))
                        .foregroundStyle(Theme.Color.bone)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Color.sage)
                        .clipShape(Capsule())
                }
                .padding(.top, Theme.Spacing.sm)

                Spacer()
            }
            
        case .found(let product):
            VStack(spacing: Theme.Spacing.md) {
                Spacer()
                
                if let urlString = product.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    } placeholder: {
                        ProgressView().frame(height: 200)
                    }
                } else {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Theme.Color.sage.opacity(0.5))
                        .frame(height: 200)
                }
                
                Text(product.name)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
                
                if let brand = product.brand {
                    Text(brand)
                        .font(Theme.Font.callout)
                        .foregroundStyle(Theme.Color.textSecondary)
                }

                Button {
                    lookupState = .scanning
                } label: {
                    Text("Scan another")
                        .font(Theme.Font.callout.weight(.semibold))
                        .foregroundStyle(Theme.Color.bone)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Color.sage)
                        .clipShape(Capsule())
                }
                .padding(.top, Theme.Spacing.sm)

                Spacer()
            }

        case .unsupported:
            unsupportedContent
        }
    }

    private var unsupportedContent: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()
            Image(systemName: Theme.Icon.barcode)
                .font(.system(size: 40))
                .foregroundStyle(Theme.Color.sage.opacity(0.4))
            Text("Barcode scanning unavailable")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            Text("This device doesn't support barcode scanning. Try searching by name instead.")
                .font(Theme.Font.callout)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
            Spacer()
        }
    }

    private func lookupBarcode(_ code: String) async {
        do {
            // First check Open Food Facts catalog
            if let product = try await barcodeService.lookup(barcode: code) {
                lookupState = .found(product)
                return
            }
            
            // Fallback to local plants repository search by code if applicable
            let results = try await dependencies.plants.search(query: code)
            if results.isEmpty {
                lookupState = .notFound(code)
            } else {
                lookupState = .notFound(code)
            }
        } catch {
            lookupState = .notFound(code)
        }
    }
}

private struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onBarcodeDetected: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .qr])],
            qualityLevel: .balanced,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        if !controller.isScanning {
            try? controller.startScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeDetected: onBarcodeDetected)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onBarcodeDetected: (String) -> Void

        init(onBarcodeDetected: @escaping (String) -> Void) {
            self.onBarcodeDetected = onBarcodeDetected
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                if case .barcode(let barcode) = item,
                   let value = barcode.payloadStringValue {
                    Task { @MainActor in
                        onBarcodeDetected(value)
                    }
                }
            }
        }
    }
}

#Preview {
    BarcodeScannerView()
        .environment(\.dependencies, .mock)
}
