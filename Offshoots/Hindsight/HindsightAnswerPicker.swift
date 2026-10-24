internal import SwiftUI

struct HindsightAnswerPicker: View {
    @Binding var selection: HindsightAnswer?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(HindsightAnswer.allCases) { answer in
                Button { selection = answer } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: selection == answer ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(answer.label).font(.body.weight(.medium))
                            Text(answer.detail).font(.caption).foregroundStyle(.secondary)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.offshootPrimary)
                .accessibilityLabel(answer.label)
                .accessibilityHint(answer.detail)
                .accessibilityAddTraits(selection == answer ? .isSelected : [])
            }
            if selection != nil {
                Button("Clear answer") { selection = nil }
                    .frame(minHeight: 44)
                    .buttonStyle(.borderless)
                    .tint(Color.offshootPrimary)
            }
        }
    }
}
