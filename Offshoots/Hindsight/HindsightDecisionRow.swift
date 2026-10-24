internal import SwiftUI

struct HindsightDecisionRow: View {
    let entry: HindsightEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.title).font(.headline)
            Text("Recorded outcome: \(entry.outcome.shortLabel)")
                .font(.subheadline).foregroundStyle(.secondary)
            HindsightHistoryLabel(answer: entry.answer, date: entry.date)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 4)
    }
}
