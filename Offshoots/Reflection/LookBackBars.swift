//
//  LookBackBars.swift
//  Offshoots
//

internal import SwiftUI
internal import Charts

/// Two stacked bars: the outcomes the user expected, and the first results they marked.
/// The axes are hidden and the labels are SwiftUI text, so the colors follow light and dark
/// mode while the app runs.
struct LookBackBars: View {
    let stats: LookBackStats

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Outcomes in either row, worst first, for the legend
    private var legend: [DecisionOutcome] {
        let shown = Set((stats.counts(\.expected) + stats.counts(\.actual)).map(\.outcome))
        return DecisionOutcome.allCases.filter { shown.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            row("Expected", \.expected)
            row("Turned out", \.actual)
            legendView
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stats.spokenRow("Expected", \.expected) + " " + stats.spokenRow("Turned out", \.actual))
    }

    private func row(_ title: String, _ outcome: KeyPath<OutcomePair, DecisionOutcome>) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(minWidth: 84, alignment: .leading)
            OutcomeBar(counts: stats.counts(outcome), total: stats.total)
        }
    }

    private var legendView: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { legendItems }
            VStack(alignment: .leading, spacing: 4) { legendItems }
        }
    }

    private var legendItems: some View {
        ForEach(legend) { outcome in
            HStack(spacing: 6) {
                Circle()
                    .fill(outcome.themeColor)
                    .frame(width: 8, height: 8)
                Text(outcome.compactLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// One stacked bar, worst outcome on the left
private struct OutcomeBar: View {
    let counts: [(outcome: DecisionOutcome, count: Int)]
    let total: Int

    var body: some View {
        Chart(counts, id: \.outcome) { item in
            BarMark(x: .value("Decisions", item.count), y: .value("Row", "row"), height: .fixed(16))
                .foregroundStyle(item.outcome.themeColor)
                .cornerRadius(4)
        }
        .chartXScale(domain: 0...max(total, 1))
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(height: 16)
    }
}
