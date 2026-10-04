//
//  UnlockReflectionSheet.swift
//  Offshoots
//

internal import SwiftUI

/// "Unlock Reflection". Shown at the tap on a locked control, never at launch.
struct UnlockReflectionSheet: View {
    let purchase: ReflectionPurchase

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image("offshootsleaf")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 88)
                        .accessibilityHidden(true)

                    Text("Read what your decisions say over time. Everything runs on your device, and only when you ask.")
                        .font(.body)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 0) {
                        FeatureRow(title: "Pattern highlights across your decisions", systemImage: "chart.line.uptrend.xyaxis")
                        Divider().padding(.leading, 52)
                        FeatureRow(title: "A reflection on each decision", systemImage: "arrow.triangle.2.circlepath")
                        Divider().padding(.leading, 52)
                        FeatureRow(title: "Clearer notes, only when you tap", systemImage: "doc.text")
                    }
                    .background(Color.offshootCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Text("Nothing appears until you tap for it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    // At accessibility sizes the buttons scroll with the content, so they cannot cover it
                    if dynamicTypeSize.isAccessibilitySize {
                        PurchaseControls(purchase: purchase, dismiss: { dismiss() })
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                if !dynamicTypeSize.isAccessibilitySize {
                    PurchaseControls(purchase: purchase, dismiss: { dismiss() })
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.offshootBackground)
                }
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

private struct FeatureRow: View {
    let title: String
    let systemImage: String

    @ScaledMetric private var iconWidth = 28.0

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Color.offshootPrimary)
                .frame(width: iconWidth)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}

private struct PurchaseControls: View {
    let purchase: ReflectionPurchase
    let dismiss: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 12) {
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
