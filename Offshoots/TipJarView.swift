//
//  TipJarView.swift
//  Offshoots
//
//  Tip jar UI for supporting the developer.
//

internal import SwiftUI
import StoreKit

struct TipJarView: View {
    @State private var tipJarManager = TipJarManager.shared

    var body: some View {
        Form {
            Section {
                productRows
            } footer: {
                Text("Tips are one-time purchases and do not unlock any features.")
            }
            .listRowBackground(Color.offshootCardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Color.offshootBackground)
        .navigationTitle("Tip Jar")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Thank You", isPresented: Bindable(tipJarManager).showThankYou) {
            Button("OK", action: resetPurchaseState)
        } message: {
            Text("Thank you for supporting Offshoots.")
        }
    }

    @ViewBuilder
    private var productRows: some View {
        if tipJarManager.products.isEmpty {
            switch tipJarManager.purchaseState {
            case .failed(let message):
                ContentUnavailableView(
                    "Tip Jar Unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )

                Button("Try Again", action: reloadProducts)
            default:
                HStack {
                    ProgressView()
                    Text("Loading tip options")
                }
            }
        } else {
            ForEach(tipJarManager.products, id: \.id) { product in
                TipProductRow(
                    product: product,
                    title: title(for: product),
                    isPurchasing: tipJarManager.purchaseState == .purchasing
                ) {
                    purchase(product)
                }
            }
        }
    }

    private func title(for product: Product) -> String {
        switch product.id {
        case TipJarManager.smallTipID:
            return "Small Tip"
        case TipJarManager.mediumTipID:
            return "Medium Tip"
        case TipJarManager.largeTipID:
            return "Large Tip"
        case TipJarManager.heroTipID:
            return "Hero Tip"
        default:
            return product.displayName
        }
    }

    private func reloadProducts() {
        Task {
            await tipJarManager.loadProducts()
        }
    }

    private func purchase(_ product: Product) {
        Task {
            await tipJarManager.purchase(product)
        }
    }

    private func resetPurchaseState() {
        tipJarManager.resetState()
    }
}

private struct TipProductRow: View {
    let product: Product
    let title: String
    let isPurchasing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: "heart")
                    .foregroundStyle(.primary)

                Spacer()

                if isPurchasing {
                    ProgressView()
                } else {
                    Text(product.displayPrice)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .disabled(isPurchasing)
    }
}

#Preview {
    NavigationStack {
        TipJarView()
    }
}
