//
//  CategoryBreakdownCard.swift
//  Offshoots
//

internal import SwiftUI
internal import Charts

struct CategoryBreakdownCard: View {
    let decisions: [Decision]

    private var categoryData: [(category: DecisionCategory, count: Int)] {
        Dictionary(grouping: decisions, by: { $0.category })
            .mapValues { $0.count }
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key.rawValue < $1.key.rawValue }
            .map { (category: $0.key, count: $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardTitle(title: "Categories", systemImage: "tag.fill")

            if categoryData.isEmpty {
                Text("No categories yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                CategoryBarChart(data: categoryData)
                    // Axis labels cannot wrap, so chart text stops growing at the largest non-accessibility size.
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
        }
        .padding(20)
        .background(Color.offshootCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

private struct CategoryBarChart: View {
    let data: [(category: DecisionCategory, count: Int)]

    @Environment(\.colorScheme) private var colorScheme
    /// Each row holds a label above its bar, so the row grows with the (capped) text.
    @ScaledMetric(relativeTo: .caption) private var rowHeight: CGFloat = 44

    var body: some View {
        Chart(data, id: \.category) { item in
            BarMark(
                x: .value("Count", item.count),
                y: .value("Category", item.category.rawValue.capitalized)
            )
            .foregroundStyle(Color.offshootPrimary)
            .cornerRadius(4)
            .annotation(position: .trailing, alignment: .leading, spacing: 8) {
                Text("\(item.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(.primary)
            }
        }
        // The axis labels keep their launch color when the color
        // scheme changes, so rebuild the chart on a change.
        .id(colorScheme)
        .frame(height: CGFloat(data.count) * rowHeight)
    }
}
