internal import SwiftUI

struct ReflectionObservationView: View {
    let observation: ReflectionObservation
    let readingID: UUID
    @Environment(ReflectionHistoryStore.self) private var history
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(observation.text)
            ForEach(observation.evidenceKeys, id: \.self) { key in
                NavigationLink {
                    ReflectionEvidenceView(readingID: readingID, evidenceKey: key)
                } label: {
                    Label(sourceLabel(key), systemImage: "text.book.closed")
                }
            }
        }
    }
    private func sourceLabel(_ key: String) -> String {
        guard let reading = history.readings.first(where: { $0.id == readingID }),
              let evidence = reading.snapshot.evidence.first(where: { $0.key == key }),
              let decision = reading.snapshot.decisions.first(where: { $0.id == evidence.decisionID }) else { return "Supporting record" }
        return "\(decision.title) · \(evidence.stage.rawValue.capitalized)"
    }

}
