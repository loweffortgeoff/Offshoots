//
//  DashboardSelection.swift
//  Offshoots
//

import Foundation

/// Which decision the Dashboard's detail pane shows on a Duo with two panes.
enum DashboardSelection {
    /// The chosen decision stays while it exists, even after it leaves Ready to Review.
    /// Marking an outcome does that, and the detail must stay to show the result banner,
    /// the payoff of a review. With nothing chosen (or the choice deleted), the first ready
    /// decision, then the most recent one, so the pane is never empty while there are decisions.
    /// `all` is newest first, as the store keeps it.
    static func current(selectedID: UUID?, ready: [Decision], all: [Decision]) -> Decision? {
        if let selectedID, let selected = all.first(where: { $0.id == selectedID }) {
            return selected
        }
        return ready.first ?? all.first
    }
}
