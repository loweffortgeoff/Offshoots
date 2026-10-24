internal import SwiftUI

struct HindsightPurchaseControls: View {
    let purchase: ReflectionPurchase
    let dismiss: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            switch purchase.state {
            case .loading, .purchasing:
                ProgressView().frame(maxWidth: .infinity)
            case .ready(let price):
                Button {
                    Task { if await purchase.buy() { dismiss() } }
                } label: {
                    Text("Unlock Hindsight • \(price)")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                Text("One-time purchase. Logging, outcomes, revisits, and notes stay free.")
                    .font(.footnote).foregroundStyle(.secondary)
            case .pending:
                Text("Your purchase is waiting for approval. Hindsight unlocks when it is approved.")
                    .font(.callout)
            case .unavailable:
                Text("The App Store is not available right now. Your saved answers remain readable.")
                    .font(.callout)
                Button("Try again") { Task { await purchase.loadProduct() } }
            case .failed(let message):
                Text(message).font(.callout)
                Button("Try again") { Task { await purchase.loadProduct() } }
            }
            Button("Restore Purchase") { Task { await purchase.restore() } }
                .frame(maxWidth: .infinity, minHeight: 44)
                .disabled(purchase.isRestoring)
            if let message = purchase.restoreMessage { Text(message).font(.caption) }
        }
        .multilineTextAlignment(.center)
        .tint(Color.offshootPrimary)
    }
}
