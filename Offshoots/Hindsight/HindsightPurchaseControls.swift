internal import SwiftUI

struct HindsightPurchaseControls: View {
    let purchase: ReflectionPurchase
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            switch purchase.state {
            case .loading, .purchasing:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 56)
            case .ready(let price):
                Button {
                    Task { if await purchase.buy() { dismiss() } }
                } label: {
                    Text("Unlock Hindsight • \(price)")
                        .font(.headline)
                        .foregroundStyle(Color.offshootOnPrimary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .padding(.horizontal, 12)
                        .background(Color.offshootPrimary, in: Capsule())
                }
                .buttonStyle(.plain)
                Text("One-time purchase. Logging, outcomes, revisits, and notes stay free.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case .pending:
                Text("Your purchase is waiting for approval. Hindsight unlocks when it is approved.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
            case .unavailable:
                Text("The App Store is not available right now. Your saved answers remain readable.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                retryButton("Try again")
            case .failed(let message):
                Text(message)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                retryButton("Try again")
            }
            Button {
                Task { await purchase.restore() }
            } label: {
                Text("Restore Purchase")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.offshootPrimary)
            .disabled(purchase.isRestoring)
            if let message = purchase.restoreMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            #if HINDSIGHT_TESTFLIGHT
            if let diagnostic = purchase.diagnostic {
                Text(diagnostic)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            #endif
        }
        .frame(maxWidth: .infinity)
    }

    private func retryButton(_ title: String) -> some View {
        Button {
            Task { await purchase.loadProduct() }
        } label: {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(Color.offshootPrimary)
    }
}
