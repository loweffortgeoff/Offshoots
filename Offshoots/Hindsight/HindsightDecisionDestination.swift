internal import SwiftUI

struct HindsightDecisionDestination: View {
    let entry: HindsightEntry
    @Environment(DecisionStore.self) private var store
    var body: some View {
        if let decision = store.decisions.first(where: { $0.id == entry.decisionID }) {
            DecisionDetailView(decision: decision)
                .safeAreaInset(edge: .top) {
                    Text("Hindsight check-in from \(entry.date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.offshootBackground)
                }
        } else {
            ContentUnavailableView("Decision unavailable", systemImage: "doc.questionmark",
                description: Text("This decision was removed or replaced. Return to Hindsight to see the current records."))
        }
    }
}
