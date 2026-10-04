internal import SwiftUI

/// Keep the compact system control at standard sizes and scale choices at accessibility sizes.
struct StakesPickerView: View {
    @Binding var selection: DecisionStakes
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 8) {
                ForEach(DecisionStakes.allCases) { stake in
                    Button {
                        selection = stake
                    } label: {
                        HStack(spacing: 12) {
                            Text(stake.label)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            if selection == stake {
                                Image(systemName: "checkmark")
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .foregroundStyle(selection == stake ? Color.offshootOnPrimary : Color.offshootPrimary)
                        .background(
                            selection == stake ? Color.offshootPrimary : Color.offshootPrimary.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(stake.label) stakes")
                    .accessibilityAddTraits(selection == stake ? .isSelected : [])
                }
            }
        } else {
            Picker("Stakes", selection: $selection) {
                ForEach(DecisionStakes.allCases) { stake in
                    Text(stake.label).tag(stake)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
