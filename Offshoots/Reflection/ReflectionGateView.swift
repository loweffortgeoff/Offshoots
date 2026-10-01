//
//  ReflectionGateView.swift
//  Offshoots
//

internal import SwiftUI

/// Wraps one Reflection surface. Hidden shows nothing. Not ready shows the control, disabled,
/// with the reason. Enabled shows the content.
struct ReflectionGateView<Content: View>: View {
    let controlTitle: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    @Environment(ReflectionCenter.self) private var center

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
            // Task 5 replaces this arm with the locked control that opens the paywall
            EmptyView()
        case .enabled:
            content()
        }
    }
}
