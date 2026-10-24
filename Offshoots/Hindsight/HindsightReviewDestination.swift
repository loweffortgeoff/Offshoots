internal import SwiftUI

/// Observe the live store at the destination, not a snapshot captured when its link was tapped.
struct HindsightReviewDestination: View {
    @Environment(DecisionStore.self) private var store
    var body: some View {
        HindsightReviewView(entries: HindsightSummary.entries(from: store.decisions))
    }
}
