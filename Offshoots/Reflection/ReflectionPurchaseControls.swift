internal import SwiftUI

struct ReflectionPurchaseControls: View {
    let purchase: ReflectionPurchase
    let dismiss: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 12) {
            switch purchase.state {
            case .loading, .purchasing:
                ProgressView().frame(maxWidth: .infinity)
            case .ready(let displayPrice):
                buyButton("Unlock Reflection • \(displayPrice)")
                Text("One-time purchase. Logging and reviewing stay free.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case .pending:
                Text("Your purchase is waiting for approval. Reflection unlocks when it is approved.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .unavailable:
                Text("The App Store is not available right now. Try again later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .failed(let message):
                Text(message).font(.subheadline).foregroundStyle(.secondary)
                buyButton("Try Again")
            }

            Button {
                Task { await purchase.restore() }
            } label: {
                // Full width at accessibility sizes, so the wrapped text does not touch the pill's edges
                Text("Restore Purchase")
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil)
            }
            .buttonStyle(.borderless)
            .tint(Color.offshootPrimary)
            .disabled(purchase.isRestoring)
            if let message = purchase.restoreMessage {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func buyButton(_ title: String) -> some View {
        Button {
            Task { if await purchase.buy() { dismiss() } }
        } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.offshootOnPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(Color.offshootPrimary)
        .controlSize(.large)
    }
}
