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

#Preview {
    AnalyticsView()
        .environmentObject(DecisionStore())
}   
