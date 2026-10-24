internal import SwiftUI

struct HindsightCheckInSection: View {
    @Binding var answer: HindsightAnswer?
    let access: HindsightAccess
    @State private var showPurchase = false

    var body: some View {
        if access.isEnabled || answer != nil {
            VStack(alignment: .leading, spacing: 12) {
                Label("Hindsight", systemImage: "arrow.uturn.backward")
                    .font(.headline)
                if access.canCapture || answer != nil {
                    Text("Would you approach this the same way?").font(.headline)
                    Text("Optional. Leave it unanswered if you prefer.")
                        .font(.caption).foregroundStyle(.secondary)
                    HindsightAnswerPicker(selection: $answer)
                    if !access.canCapture {
                        Text("Ownership could not be confirmed. Your draft is still here. Restore your purchase or clear the optional answer to save this review.")
                            .font(.callout).foregroundStyle(.secondary)
                            .accessibilityIdentifier("hindsightOwnershipMessage")
                        if let purchase = access.purchase {
                            Button("Restore Purchase") { Task { await purchase.restore() } }
                                .disabled(purchase.isRestoring)
                            if let message = purchase.restoreMessage { Text(message).font(.caption) }
                        }
                    }
                } else {
                    Button { showPurchase = true } label: {
                        Label("Add a Hindsight check-in", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    Text("Record what you would repeat or change. Your outcome and notes stay free.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .tint(Color.offshootPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.offshootCardBackground, in: RoundedRectangle(cornerRadius: 16))
            .sheet(isPresented: $showPurchase) {
                if let purchase = access.purchase { HindsightPurchaseSheet(purchase: purchase) }
            }
        }
    }
}
