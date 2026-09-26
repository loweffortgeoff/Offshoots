//
//  ReviewDatePresetRow.swift
//  Offshoots
//

internal import SwiftUI

/// Chips that set the review date. A chip is selected while the date falls on its day.
/// One row when it fits, two rows of two next, then a column at large text sizes
struct ReviewDatePresetRow: View {
    @Binding var date: Date

    var body: some View {
        let selected = ReviewDatePreset.matching(date)
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                ForEach(ReviewDatePreset.allCases) { preset in
                    ReviewDatePresetChip(preset: preset, isSelected: preset == selected) {
                        date = preset.date()
                    }
                }
            }
            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    ReviewDatePresetChip(preset: .tomorrow, isSelected: selected == .tomorrow) {
                        date = ReviewDatePreset.tomorrow.date()
                    }
                    ReviewDatePresetChip(preset: .threeDays, isSelected: selected == .threeDays) {
                        date = ReviewDatePreset.threeDays.date()
                    }
                }
                GridRow {
                    ReviewDatePresetChip(preset: .oneWeek, isSelected: selected == .oneWeek) {
                        date = ReviewDatePreset.oneWeek.date()
                    }
                    ReviewDatePresetChip(preset: .oneMonth, isSelected: selected == .oneMonth) {
                        date = ReviewDatePreset.oneMonth.date()
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(ReviewDatePreset.allCases) { preset in
                    ReviewDatePresetChip(preset: preset, isSelected: preset == selected) {
                        date = preset.date()
                    }
                }
            }
        }
    }
}

struct ReviewDatePresetChip: View {
    let preset: ReviewDatePreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(preset.label)
                .font(.subheadline)
                .fontWeight(.medium)
                // Ideal width, so ViewThatFits moves to the next layout before a label truncates
                .fixedSize()
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .foregroundStyle(isSelected ? Color.offshootOnPrimary : Color.offshootPrimary)
                .background(
                    isSelected ? Color.offshootPrimary : Color.offshootPrimary.opacity(0.12),
                    in: Capsule()
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var date = ReviewDatePreset.tomorrow.date()
    ReviewDatePresetRow(date: $date)
        .padding()
}
