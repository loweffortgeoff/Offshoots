//
//  ReflectionStateView.swift
//  Offshoots
//

internal import SwiftUI

/// Idle, loading, result and error for one Reflection card. The result stays on screen with
/// Refresh and Copy. Nothing is saved.
struct ReflectionStateView<Value: Equatable, ResultContent: View>: View {
    let state: ReflectionViewState<Value>
    let startTitle: String
    let systemImage: String
    let start: () -> Void
    let copyText: (Value) -> String
    @ViewBuilder let result: (Value) -> ResultContent

    var body: some View {
        switch state {
        case .idle:
            Button(action: start) {
                Label(startTitle, systemImage: systemImage)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.offshootPrimary)

        case .loading:
            HStack(spacing: 12) {
                ProgressView()
                Text("Reading your decisions…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Reading your decisions")

        case .result(let value):
            VStack(alignment: .leading, spacing: 16) {
                result(value)
                ResultActions(start: start, copy: { copy(copyText(value)) })
            }

        case .error(let message):
            VStack(alignment: .leading, spacing: 12) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button(action: start) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .tint(Color.offshootPrimary)
            }
        }
    }

    private func copy(_ text: String) {
        // SwiftUI has no pasteboard API on iOS, so this is the one UIKit call in the feature
        UIPasteboard.general.string = text
    }
}

/// Refresh and Copy. At accessibility sizes the two stack instead of wrapping mid-word.
private struct ResultActions: View {
    let start: () -> Void
    let copy: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack { buttons }
                .buttonStyle(.bordered)
                .tint(Color.offshootPrimary)
            VStack(alignment: .leading) { buttons }
                .buttonStyle(.bordered)
                .tint(Color.offshootPrimary)
        }
    }

    @ViewBuilder private var buttons: some View {
        Button(action: start) {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
        Button(action: copy) {
            Label("Copy", systemImage: "doc.on.doc")
        }
    }
}
