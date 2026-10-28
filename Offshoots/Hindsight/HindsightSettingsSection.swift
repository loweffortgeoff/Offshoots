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
                }
                Button("Restore Purchase") { Task { await purchase.restore() } }
                    .disabled(purchase.isRestoring)
                    // One row that is always present: on the Section the sheet repeats per row and a
                    // row rebuild dismisses it (9f89d50); on Explore it goes when a Restore unlocks.
                    .sheet(isPresented: $showPurchase) { HindsightPurchaseSheet(purchase: purchase) }
                if let message = purchase.restoreMessage { Text(message).font(.caption) }
            } header: { Text("Hindsight") }
            footer: { Text("Saved answers remain readable and exportable if ownership changes.") }
            .tint(Color.offshootPrimary)
            .listRowBackground(Color.offshootCardBackground)
        }
    }
}
