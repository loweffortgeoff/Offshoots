//
//  UnlockReflectionSheet.swift
//  Offshoots
//

internal import SwiftUI

/// "Unlock Reflection". Shown at the tap on a locked control, never at launch.
struct UnlockReflectionSheet: View {
    let purchase: ReflectionPurchase

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Read what your decisions say over time. Everything runs on your device, and only when you ask.")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 16) {
                        Label("Pattern highlights across your decisions", systemImage: "chart.bar.doc.horizontal")
                        Label("A reflection on each decision", systemImage: "text.book.closed")
                        Label("Clearer notes, only when you tap", systemImage: "square.and.pencil")
                    }
                    .font(.body)

                    PurchaseControls(purchase: purchase, dismiss: { dismiss() })
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.offshootBackground)
            .navigationTitle("Unlock Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await purchase.loadProduct() }
        }
    }
}

private struct PurchaseControls: View {
    let purchase: ReflectionPurchase
    let dismiss: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch purchase.state {
            case .loading, .purchasing:
                ProgressView().frame(maxWidth: .infinity)
            case .ready(let displayPrice):
                buyButton("Unlock Reflection for \(displayPrice)")
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
            .buttonStyle(.bordered)
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
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.offshootPrimary)
        .controlSize(.large)
    }
}
