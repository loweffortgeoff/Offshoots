//
//  OutcomeTrendCard.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI
internal import Charts

struct OutcomeTrendCard: View {
    let decisions: [Decision]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private struct WeekData: Identifiable {
        let id = UUID()
        let weekStart: Date
        let category: String
        let count: Int
    }

    private var weeklyData: [WeekData] {
        let calendar = Calendar.current
        let now = Date()
        var result: [WeekData] = []

        // Get the last 8 weeks
        for weekOffset in (0..<8).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { continue }
            let startOfWeek = calendar.startOfDay(for: calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart))!)
            guard let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else { continue }

            let weekDecisions = decisions.filter { decision in
                guard let resolvedDate = decision.resolvedDate else { return false }
                return resolvedDate >= startOfWeek && resolvedDate < endOfWeek
            }

            // Group into Positive (VeryGood, Good), Neutral, Negative (Bad, VeryBad)
            let positiveCount = weekDecisions.filter { $0.currentOutcome?.isPositive == true }.count
            let neutralCount = weekDecisions.filter { $0.currentOutcome == .neutral }.count
            let negativeCount = weekDecisions.filter { $0.currentOutcome?.isNegative == true }.count

            result.append(WeekData(weekStart: startOfWeek, category: "Positive", count: positiveCount))
            result.append(WeekData(weekStart: startOfWeek, category: "Neutral", count: neutralCount))
            result.append(WeekData(weekStart: startOfWeek, category: "Negative", count: negativeCount))
        }

        return result
    }

    private var hasData: Bool {
        weeklyData.contains { $0.count > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardTitle(title: "Outcome Trends", systemImage: "chart.bar.fill", note: "Last 8 weeks")

            if !hasData {
                Text("No completed decisions to show trends")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(weeklyData) { item in
                    BarMark(
                        x: .value("Week", item.weekStart, unit: .weekOfYear),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(by: .value("Category", item.category))
                    .cornerRadius(2)
                }
                .chartForegroundStyleScale([
                    "Positive": Color.outcomeGood,
                    "Neutral": Color.outcomeNeutral,
                    "Negative": Color.outcomeBad
                ])
                .chartXAxis {
                    // Eight week labels fit only at the default text size; above it, label every second week.
                    AxisMarks(values: .stride(by: .weekOfYear, count: dynamicTypeSize > .large ? 2 : 1)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartLegend(position: .bottom, spacing: 16)
                .frame(height: 200)
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
