//
//  AnalyticsView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI
internal import Charts

struct AnalyticsView: View {
    @EnvironmentObject var store: DecisionStore

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.offshootPrimary.opacity(0.05),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if store.decisions.isEmpty {
                            EmptyAnalyticsView()
                        } else {
                            // Overall Stats
                            OverallStatsCard(decisions: store.decisions)

                            // Decision Timeline
                            DecisionTimelineCard(decisions: store.decisions)

                            // Category Breakdown
                            CategoryBreakdownCard(decisions: store.decisions)

                            // Outcome Distribution
                            OutcomeDistributionCard(decisions: store.decisions)

                            // Outcome Trends
                            OutcomeTrendCard(decisions: store.decisions)

                            // Prediction Accuracy
                            PredictionAccuracyCard(decisions: store.decisions)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct EmptyAnalyticsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundStyle(Color.offshootPrimary.opacity(0.3))

            Text("No Data Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.offshootPrimary)

            Text("Log and complete decisions to see your insights and analytics here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct OverallStatsCard: View {
    let decisions: [Decision]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Overview", systemImage: "chart.pie.fill")
                .font(.headline)
                .foregroundStyle(Color.offshootPrimary)

            let total = decisions.count
            let completed = decisions.filter { $0.actual != nil }.count
            let pending = total - completed
            let accuracy = AnalyticsEngine.predictionAccuracy(from: decisions)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatBox(title: "Total", value: "\(total)", icon: "square.stack.3d.up.fill", color: .offshootPrimary)
                StatBox(title: "Completed", value: "\(completed)", icon: "checkmark.circle.fill", color: .outcomeGood)
                StatBox(title: "Pending", value: "\(pending)", icon: "hourglass", color: .outcomePending)
                StatBox(title: "Accuracy", value: "\(accuracy)%", icon: "target", color: .offshootPrimary)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct CategoryBreakdownCard: View {
    let decisions: [Decision]

    private var categoryData: [(category: DecisionCategory, count: Int)] {
        Dictionary(grouping: decisions, by: { $0.category })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .map { (category: $0.key, count: $0.value) }
    }

    private func color(for category: DecisionCategory) -> Color {
        switch category {
        case .work: return .blue
        case .money: return .green
        case .health: return .red
        case .relationships: return .pink
        case .home: return .orange
        case .other: return .purple
        }
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
                    .foregroundStyle(color(for: item.category))
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
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct OutcomeDistributionCard: View {
    let decisions: [Decision]

    private var outcomeData: [(outcome: DecisionOutcome, count: Int)] {
        let completed = decisions.filter { $0.actual != nil }
        return DecisionOutcome.allCases.compactMap { outcome in
            let count = completed.filter { $0.actual == outcome }.count
            return count > 0 ? (outcome: outcome, count: count) : nil
        }
    }

    private var totalCompleted: Int {
        decisions.filter { $0.actual != nil }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Outcomes", systemImage: "chart.pie.fill")
                .font(.headline)
                .foregroundStyle(Color.offshootPrimary)

            if totalCompleted == 0 {
                Text("No completed decisions yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 20) {
                    Chart(outcomeData, id: \.outcome) { item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(item.outcome.themeColor)
                        .cornerRadius(4)
                    }
                    .frame(width: 120, height: 120)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(outcomeData, id: \.outcome) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.outcome.themeColor)
                                    .frame(width: 8, height: 8)
                                Text(item.outcome.compactLabel)
                                    .font(.caption)
                                Spacer()
                                Text("\(Int(Double(item.count) / Double(totalCompleted) * 100))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(item.outcome.themeColor)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct PredictionAccuracyCard: View {
    let decisions: [Decision]

    private var completed: [Decision] {
        decisions.filter { $0.actual != nil }
    }

    private var accurate: Int {
        completed.filter { $0.expected == $0.actual }.count
    }

    private var accuracyData: [(label: String, count: Int, color: Color)] {
        [
            (label: "Correct", count: accurate, color: .outcomeGood),
            (label: "Incorrect", count: completed.count - accurate, color: .outcomeBad)
        ].filter { $0.count > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Prediction Accuracy", systemImage: "target")
                .font(.headline)
                .foregroundStyle(Color.offshootPrimary)

            if completed.isEmpty {
                Text("No completed decisions to analyze")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                let accuracy = Double(accurate) / Double(completed.count)

                VStack(spacing: 16) {
                    ZStack {
                        Chart(accuracyData, id: \.label) { item in
                            SectorMark(
                                angle: .value("Count", item.count),
                                innerRadius: .ratio(0.7),
                                angularInset: 2
                            )
                            .foregroundStyle(item.color)
                            .cornerRadius(4)
                        }
                        .frame(width: 140, height: 140)

                        VStack(spacing: 4) {
                            Text("\(Int(accuracy * 100))%")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(Color.offshootPrimary)

                            Text("Accurate")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Correct")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(accurate)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.outcomeGood)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Incorrect")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(completed.count - accurate)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.outcomeBad)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct DecisionTimelineCard: View {
    let decisions: [Decision]

    private var timelineData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let now = Date()

        // Get the last 30 days
        var result: [(date: Date, count: Int)] = []
        for dayOffset in (0..<30).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let count = decisions.filter { calendar.isDate($0.createdAt, inSameDayAs: startOfDay) }.count
            result.append((date: startOfDay, count: count))
        }
        return result
    }

    private var totalRecent: Int {
        timelineData.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Decision Activity", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                    .foregroundStyle(Color.offshootPrimary)
                Spacer()
                Text("Last 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if totalRecent == 0 {
                Text("No decisions in the last 30 days")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(timelineData, id: \.date) { item in
                    AreaMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Decisions", item.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.offshootPrimary.opacity(0.3), Color.offshootPrimary.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Decisions", item.count)
                    )
                    .foregroundStyle(Color.offshootPrimary)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct OutcomeTrendCard: View {
    let decisions: [Decision]

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
                decision.actual != nil &&
                decision.createdAt >= startOfWeek &&
                decision.createdAt < endOfWeek
            }

            // Group into Positive (VeryGood, Good), Neutral, Negative (Bad, VeryBad)
            let positiveCount = weekDecisions.filter { $0.actual?.isPositive == true }.count
            let neutralCount = weekDecisions.filter { $0.actual == .neutral }.count
            let negativeCount = weekDecisions.filter { $0.actual?.isNegative == true }.count

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
            HStack {
                Label("Outcome Trends", systemImage: "chart.bar.fill")
                    .font(.headline)
                    .foregroundStyle(Color.offshootPrimary)
                Spacer()
                Text("Last 8 weeks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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
                    AxisMarks(values: .stride(by: .weekOfYear)) { _ in
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
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(DecisionStore())
}   
