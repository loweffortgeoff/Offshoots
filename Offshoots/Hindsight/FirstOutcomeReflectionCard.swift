internal import SwiftUI

struct FirstOutcomeReflectionCard: View {
    let note: String?
    let hindsight: HindsightAnswer?
    let date: Date?

    var body: some View {
        if note != nil || hindsight != nil {
            VStack(alignment: .leading, spacing: 12) {
                Label("Reflection", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundStyle(Color.offshootPrimary)
                if let hindsight, let date { HindsightHistoryLabel(answer: hindsight, date: date) }
                if let note { Text(note).font(.body).foregroundStyle(.primary) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.offshootCardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }
}
