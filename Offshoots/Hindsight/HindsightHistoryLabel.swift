internal import SwiftUI

struct HindsightHistoryLabel: View {
    let answer: HindsightAnswer
    let date: Date
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(answer.label, systemImage: "arrow.uturn.backward")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.offshootPrimary)
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption).foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hindsight: \(answer.label), \(date.formatted(date: .abbreviated, time: .omitted))")
    }
}
