internal import SwiftUI

struct HindsightDecisionRow: View {
    let entry: HindsightEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.title).font(.headline)
            Text(entry.category.rawValue.capitalized)
                .font(.subheadline).foregroundStyle(.secondary)
            Text("Recorded outcome: \(entry.outcome.shortLabel)")
                .font(.subheadline).foregroundStyle(.secondary)
            HindsightHistoryLabel(answer: entry.answer, date: entry.date)
            if let note = entry.note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(note)
            } else {
                Text("No note recorded.").foregroundStyle(.secondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 4)
    }
}
