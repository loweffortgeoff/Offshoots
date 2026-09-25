//
//  OutcomePickerView.swift
//  Offshoots
//

internal import SwiftUI

struct OutcomePickerView: View {
    @Binding var selection: DecisionOutcome

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // Five across normally; one full-width row per outcome at accessibility sizes.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))

        layout {
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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isRow = dynamicTypeSize.isAccessibilitySize
        let layout = isRow
            ? AnyLayout(HStackLayout(spacing: 12))
            : AnyLayout(VStackLayout(spacing: 6))

        Button(action: action) {
            layout {
                OutcomeIcon(outcome: outcome)
                    .font(isSelected ? .title2 : .title3)
                    .accessibilityHidden(true)

                Text(outcome.compactLabel)
                    .font(isRow ? .body : .caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: isRow ? .leading : .center)
            .padding(.vertical, 12)
            .padding(.horizontal, isRow ? 16 : 0)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? outcome.themeColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? outcome.themeColor : Color.clear, lineWidth: 2)
            )
            // The whole tile takes the tap, not only the icon and text pixels.
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? outcome.themeColor : .secondary)
        .accessibilityLabel(outcome.shortLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
