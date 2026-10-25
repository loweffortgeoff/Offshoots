internal import SwiftUI

struct HindsightSettingsSection: View {
    @Environment(HindsightAccess.self) private var access
    @State private var showPurchase = false
    var body: some View {
        if access.isEnabled, let purchase = access.purchase {
            Section {
                if access.canCapture {
                    Label("Hindsight is unlocked", systemImage: "checkmark.circle")
                } else {
                    Button("Explore Hindsight") { showPurchase = true }
                        .sheet(isPresented: $showPurchase) { HindsightPurchaseSheet(purchase: purchase) }
                }
                Button("Restore Purchase") { Task { await purchase.restore() } }
                    .disabled(purchase.isRestoring)
                if let message = purchase.restoreMessage { Text(message).font(.caption) }
            } header: { Text("Hindsight") }
            footer: { Text("Saved answers remain readable and exportable if ownership changes.") }
            .tint(Color.offshootPrimary)
            .listRowBackground(Color.offshootCardBackground)
        }
    }
}
