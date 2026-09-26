//
//  QuickStatsSection.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct QuickStatsSection: View {
    @Environment(DecisionStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .accessibilityHidden(true)
                    .foregroundStyle(Color.offshootPrimary)
                Text("Quick Stats")
                    .font(.headline)
                    .foregroundStyle(Color.offshootPrimary)
            }

            let goodPercentage = AnalyticsEngine.goodOutcomePercentage(from: store.decisions)
            let topCategory = AnalyticsEngine.topCategory(from: store.decisions)
            let trendResult = AnalyticsEngine.qualityTrend(from: store.decisions)
            let trend = trendResult.trend

            tileLayout {
                QuickStatTile(
                    icon: "leaf.fill",
                    iconColor: .outcomeGood,
                    title: "Outcomes",
                    value: "\(goodPercentage)% good",
                    valueColor: .outcomeGood
                )
                QuickStatTile(
                    icon: "star.fill",
                    iconColor: .offshootPrimary,
                    title: "Top Category",
                    value: topCategory
                )
                QuickStatTile(
                    icon: trendIcon(for: trend),
                    iconColor: trendColor(for: trend),
                    title: trendResult.isSoFar ? "Trend · So far" : "Trend",
                    value: trend.label,
                    valueColor: trendColor(for: trend),
                    spokenTitle: trendResult.isSoFar ? "Trend so far" : nil
                )
            }
            // Equal tile heights: the row takes its tallest tile's height.
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Three across normally; stacked at accessibility sizes so words never break.
    private var tileLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
    }

    private func trendIcon(for trend: QualityTrend) -> String {
        switch trend {
        case .improving: return "arrow.up.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        case .tooEarly: return "hourglass.circle.fill"
        }
    }

    private func trendColor(for trend: QualityTrend) -> Color {
        switch trend {
        case .improving: return .outcomeGood
        case .declining: return .outcomeBad
        case .stable, .tooEarly: return .outcomeNeutral
        }
    }
}

#Preview {
    QuickStatsSection()
}
