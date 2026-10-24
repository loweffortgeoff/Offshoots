//
//  ReflectionSettingsSection.swift
//  Offshoots
//

internal import SwiftUI

/// The restore path App Review expects. Shown only where Reflection can run.
struct ReflectionSettingsSection: View {
    @Environment(ReflectionCenter.self) private var center

    var body: some View {
        if let purchase = center.purchase {
            Section {
                if center.isUnlocked {
                    Label("Reflection is unlocked", systemImage: "checkmark.circle")
                }
                Button {
                    Task { await purchase.restore() }
                } label: {
                    Label("Restore Purchase", systemImage: "arrow.clockwise")
                }
                .disabled(purchase.isRestoring)
                if let message = purchase.restoreMessage {
                    Text(message).font(.caption).foregroundStyle(.secondary)
                }
            } header: {
                Text("Reflection")
            } footer: {
                Text("Saved readings remain available when generation is unavailable.")
            }
            .listRowBackground(Color.offshootCardBackground)
        }
    }
}
