internal import SwiftUI

struct ReflectionEvidenceView: View {
    let readingID: UUID
    let evidenceKey: String
    @Environment(ReflectionHistoryStore.self) private var history
    @Environment(DecisionStore.self) private var store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let reading = history.readings.first(where: { $0.id == readingID }),
                   let evidence = reading.snapshot.evidence.first(where: { $0.key == evidenceKey }) {
                    Text("At generation").font(.headline)
                    Text(evidence.date, format: .dateTime.month().day().year())
                    Text(evidence.stage.rawValue.capitalized).foregroundStyle(.secondary)
                    Text(evidence.text).textSelection(.enabled)
                    if let current = store.decisions.first(where: { $0.id == evidence.decisionID }) {
                        NavigationLink { DecisionDetailView(decision: current) } label: {
                            Label("Open current decision: \(current.title)", systemImage: "arrow.up.forward.square")
                        }
                    } else {
                        Text("The original decision was deleted. This evidence was kept with the saved reading.")
                            .foregroundStyle(.secondary)
                    }
                } else { Text("This saved evidence is no longer available.") }
            }.padding().frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Evidence").navigationBarTitleDisplayMode(.inline)
        .background(Color.offshootBackground)
    }
}
