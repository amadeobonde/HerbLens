import SwiftUI

/// Post-identify card. Spring-animates the celebration mascot, shows a confidence arc,
/// plant identity, and the primary action buttons. Low-confidence results surface the
/// candidate chip row so the user picks the match themselves.
struct ScanResultView: View {
    let result: ScanResult
    let tier: SubscriptionTier
    let onSave: () -> Void
    let onScanAnother: () -> Void
    let onPickCandidate: (Plant) -> Void
    let onOpenVault: (() -> Void)?

    @State private var celebrating: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                hero
                identity
                if result.isLowConfidence, result.identification.suggestedMatches.count > 1 {
                    CandidateChipsRow(
                        candidates: result.identification.suggestedMatches,
                        selectedID: result.selectedPlant?.id,
                        onSelect: onPickCandidate
                    )
                    .padding(.horizontal, Theme.Spacing.md)
                }
                actions
            }
            .padding(.vertical, Theme.Spacing.xl)
        }
        .background(Theme.Color.background)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                celebrating = true
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottom) {
            Image(uiImage: result.image)
                .resizable()
                .scaledToFill()
                .frame(height: 280)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [Color.clear, Theme.Color.background.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            if celebrating {
                Image("Scan/BambooCelebrating")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .offset(y: 40)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .frame(height: 300)
    }

    private var identity: some View {
        VStack(spacing: Theme.Spacing.sm) {
            confidenceArc
                .frame(width: 96, height: 96)

            VStack(spacing: Theme.Spacing.xxs) {
                Text(displayPlant?.commonName ?? result.identification.rawIdentification ?? "Unknown plant")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .multilineTextAlignment(.center)

                if let scientific = displayPlant?.alternateNames.first {
                    Text(scientific)
                        .font(Theme.Font.body)
                        .italic()
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }

            if let description = displayPlant?.description ?? result.identification.rawIdentification {
                Text(description)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private var confidenceArc: some View {
        let confidence = result.identification.confidence
        let clamped = min(max(confidence, 0), 1)
        return ZStack {
            Circle()
                .stroke(Theme.Color.bone.opacity(0.8), lineWidth: 10)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    arcGradient,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(Int(clamped * 100))%")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("match")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
    }

    private var arcGradient: AngularGradient {
        let confidence = result.identification.confidence
        let colors: [Color]
        if confidence >= 0.85 {
            colors = [Theme.Color.forest, Theme.Color.sage]
        } else if confidence >= ScanResult.lowConfidenceThreshold {
            colors = [Theme.Color.amber, Theme.Color.sage]
        } else {
            colors = [Theme.Color.ember, Theme.Color.amber]
        }
        return AngularGradient(colors: colors, center: .center)
    }

    private var actions: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button(action: onSave) {
                Text("Save to Vault")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.bone)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Capsule().fill(Theme.Color.sage))
            }
            .disabled(result.selectedPlant == nil)
            .opacity(result.selectedPlant == nil ? 0.5 : 1)

            Button(action: onScanAnother) {
                Text(tier == .premium ? "Scan another instantly" : "Scan another")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
            }
            .glass(.capsule)

            if let onOpenVault {
                Button("Open Vault", action: onOpenVault)
                    .font(Theme.Font.callout)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private var displayPlant: Plant? {
        result.selectedPlant ?? result.identification.suggestedMatches.first
    }
}
