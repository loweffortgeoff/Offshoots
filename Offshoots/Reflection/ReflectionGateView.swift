//
//  ReflectionGateView.swift
//  Offshoots
//

internal import SwiftUI

/// Wraps one Reflection surface. Hidden shows nothing. Not ready shows the control, disabled,
/// with the reason. Paywalled shows the control with a lock. Enabled shows the content.
struct ReflectionGateView<Content: View>: View {
    let controlTitle: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    @Environment(ReflectionCenter.self) private var center
    @State private var showPaywall = false

    var body: some View {
        switch center.gate {
        case .hidden:
            EmptyView()
        case .notReady(let reason):
            VStack(alignment: .leading, spacing: 8) {
                Button {} label: {
                    Label(controlTitle, systemImage: systemImage)
                }
                .buttonStyle(.bordered)
                .disabled(true)
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .paywalled:
            // Looks like the enabled control, with a lock. The paywall opens only on this tap.
            Button { showPaywall = true } label: {
                Label(controlTitle, systemImage: "lock")
            }
            .buttonStyle(.bordered)
            .tint(Color.offshootPrimary)
            .accessibilityHint("Opens Unlock Reflection")
            .sheet(isPresented: $showPaywall) {
                if let purchase = center.purchase {
                    UnlockReflectionSheet(purchase: purchase)
                }
            }
        case .enabled:
            content()
        }
    }
}
