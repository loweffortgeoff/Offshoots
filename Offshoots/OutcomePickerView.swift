//
//  OutcomePickerView.swift
//  Offshoots
//

internal import SwiftUI

struct OutcomePickerView: View {
    @Binding var selection: DecisionOutcome

    var body: some View {
        HStack(spacing: 8) {
            ForEach(DecisionOutcome.allCases) { outcome in
                OutcomeButton(
                    outcome: outcome,
                    isSelected: selection == outcome
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selection = outcome
                    }
                }
            }
        }
    }
}

struct OutcomeButton: View {
    let outcome: DecisionOutcome
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                OutcomeIcon(outcome: outcome)
                    .font(isSelected ? .title2 : .title3)

                Text(outcome.compactLabel)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? outcome.themeColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? outcome.themeColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? outcome.themeColor : .secondary)
    }
}
