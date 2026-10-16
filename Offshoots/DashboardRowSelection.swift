//
//  DashboardRowSelection.swift
//  Offshoots
//

internal import SwiftUI

/// How a Dashboard row behaves when the Dashboard has a detail pane beside it (wide Duo).
struct DashboardRowSelection {
    /// The decision the detail pane shows, so the default selection is highlighted too
    let selectedID: UUID?
    let select: (Decision) -> Void
}

/// A Dashboard decision row. With no `selection` it pushes the detail, as on a phone.
/// With one, a tap shows the decision in the detail pane, and the shown row is highlighted
/// the same way as in the Decisions list.
struct DashboardDecisionRow: View {
    @Environment(DecisionStore.self) private var store
    let decision: Decision
    var selection: DashboardRowSelection?

    var body: some View {
        let rowView = DecisionRowView(decision: decision, isReadyForReview: decision.isReadyForReview(asOf: store.today))
        if let selection {
            let isSelected = selection.selectedID == decision.id
            Button {
                selection.select(decision)
            } label: {
                rowView
            }
            .buttonStyle(.plain)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.offshootPrimary, lineWidth: 2)
                }
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            NavigationLink {
                DecisionDetailView(decision: decision)
            } label: {
                rowView
            }
            .buttonStyle(.plain)
        }
    }
}
