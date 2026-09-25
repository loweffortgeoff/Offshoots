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
            .sorted { $0.value > $1.value }
            .map { (category: $0.key, count: $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Categories", systemImage: "tag.fill")
                .font(.headline)
                .foregroundStyle(Color.offshootPrimary)

            if categoryData.isEmpty {
                Text("No categories yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(categoryData, id: \.category) { item in
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
                            .foregroundStyle(Color.primary)
                    }
                }
                .frame(height: CGFloat(categoryData.count) * 44)
            }
        }
        .padding(20)
        .background(Color.offshootCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}
