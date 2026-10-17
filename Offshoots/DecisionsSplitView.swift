//
//  DecisionsSplitView.swift
//  Offshoots
//

internal import SwiftUI

/// List first, detail second: side by side in wide landscape, one above the other when the
/// Duo is partly open in portrait. When the Duo is partly open, the system puts the fold
/// between the two.
@available(iOS 27.1, *)
struct DecisionsSplitView<Primary: View>: View {
    let arrangement: PaneArrangement
    let selection: Decision?
    private let primary: Primary

    init(arrangement: PaneArrangement, selection: Decision?, @ViewBuilder primary: () -> Primary) {
        self.arrangement = arrangement
        self.selection = selection
        self.primary = primary()
    }

    var body: some View {
        WidePanes(arrangement: arrangement) {
            primary
        } secondary: {
            NavigationStack {
                if let selection {
                    DecisionDetailView(decision: selection)
                        .id(selection.id)
                } else {
                    placeholder
                }
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.offshootBackground
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.largeTitle)
                    .foregroundStyle(Color.offshootPrimary.opacity(0.6))
                    .accessibilityHidden(true)
                Text("Select a decision")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
