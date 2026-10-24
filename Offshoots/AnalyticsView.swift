//
//  AnalyticsView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI
internal import Charts

struct AnalyticsView: View {
    @Environment(DecisionStore.self) private var store
    @Environment(ReflectionCenter.self) private var reflection
    @Environment(ReflectionHistoryStore.self) private var history

    var body: some View {
        TwoPaneReader { arrangement in
            if arrangement != .single, #available(iOS 27.1, *) {
                // With no decisions the empty state stays in the first pane, clear of the fold
                if store.decisions.isEmpty {
                    WidePanes(arrangement: arrangement) {
                        pane(title: "Insights", inline: arrangement == .stacked) {
                            EmptyAnalyticsView()
                            if !history.readings.isEmpty { ReflectionReadingCard(kind: .patterns) }
                        }
                    } secondary: {
                        Color.offshootBackground
                            .ignoresSafeArea()
                    }
                } else {
                    WidePanes(arrangement: arrangement) {
                        pane(title: "Insights", inline: arrangement == .stacked) { whatYouDecideCards }
                    } secondary: {
                        pane(title: "Outcomes", inline: arrangement == .stacked) { howItTurnedOutCards }
                    }
                }
            } else {
                pane(title: "Insights") {
                    if store.decisions.isEmpty {
                        EmptyAnalyticsView()
                        if !history.readings.isEmpty { ReflectionReadingCard(kind: .patterns) }
                    } else {
                        whatYouDecideCards
                        howItTurnedOutCards
                    }
                }
            }
        }
    }

    /// Cards about the decisions themselves. The first pane on a Duo with two panes.
    @ViewBuilder
    private var whatYouDecideCards: some View {
        // Overall Stats
        OverallStatsCard(decisions: store.decisions)

        // Decision Timeline
        DecisionTimelineCard(decisions: store.decisions)

        // Category Breakdown
        CategoryBreakdownCard(decisions: store.decisions)

        // Outcome Distribution
        OutcomeDistributionCard(decisions: store.decisions)
    }

    /// Cards about how decisions turned out. The second pane on a Duo with two panes, titled "Outcomes".
    @ViewBuilder
    private var howItTurnedOutCards: some View {
        // Outcome Trends
        OutcomeTrendCard(decisions: store.decisions)

        // Prediction Accuracy
        PredictionAccuracyCard(decisions: store.decisions)

        // Optimism Bias
        OptimismCard(
            bias: AnalyticsEngine.optimismBias(from: store.decisions),
            markedCount: AnalyticsEngine.markedCount(from: store.decisions)
        )

        // Patterns (Reflection unlock, on-device text). Unsupported devices never see it.
        // Removing the card also drops its result, so a stale one cannot come back.
        if ReflectionVisibility.showEntry(gate: reflection.gate, savedCount: history.readings.count) {
            PatternsCard(decisions: store.decisions, hasNotes: ReflectionEligibility.hasNotesForPatterns(store.decisions))
        }
    }

    /// One scrolling column of cards under a title. Each pane on a Duo with two panes has its
    /// own title, so the two columns start level. Stacked panes are only about 456 pt tall,
    /// so their titles are inline: a large title would take a fifth of the pane.
    private func pane<Cards: View>(title: String, inline: Bool = false, @ViewBuilder cards: () -> Cards) -> some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.offshootPrimary.opacity(0.05),
                        Color.offshootBackground
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        cards()

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(inline ? .inline : .large)
        }
    }
}

struct EmptyAnalyticsView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 60
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .accessibilityHidden(true)
                .font(.system(size: iconSize))
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
                    .accessibilityHidden(true)
                    .font(.callout)
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
        .background(Color.offshootCardBackground)
        .cornerRadius(12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
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
            CardTitle(title: "Decision Activity", systemImage: "chart.line.uptrend.xyaxis", note: "Last 30 days")

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
                // Axis labels cannot wrap, so chart text stops growing at the largest non-accessibility size.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(ChartSummary.activity(dailyCounts: timelineData.map(\.count), days: 30))
            }
        }
        .padding(20)
        .background(Color.offshootCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

#Preview {
    AnalyticsView()
        .environment(DecisionStore())
        .environment(ReflectionCenter.make())
}   
