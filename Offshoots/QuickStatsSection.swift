//
//  QuickStatsSection.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct QuickStatsSection: View {
    @EnvironmentObject var store: DecisionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.offshootPrimary)
                Text("Quick Stats")
                    .font(.headline)
                    .foregroundStyle(Color.offshootPrimary)
            }

            HStack(spacing: 12) {
                let goodPercentage = AnalyticsEngine.goodOutcomePercentage(from: store.decisions)
                let topCategory = AnalyticsEngine.topCategory(from: store.decisions)
                let trend = AnalyticsEngine.qualityTrend(from: store.decisions)

                PrimaryCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.outcomeGood)
                            Spacer()
                        }
                        Text("Outcomes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Good \(goodPercentage)%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.outcomeGood)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.offshootPrimary)
                            Spacer()
                        }
                        Text("Top Category")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(topCategory)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: trendIcon(for: trend))
                                .font(.system(size: 16))
                                .foregroundStyle(trendColor(for: trend))
                            Spacer()
                        }
                        Text("Trend")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(trend)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(trendColor(for: trend))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func trendIcon(for trend: String) -> String {
        switch trend {
        case "Improving": return "arrow.up.circle.fill"
        case "Declining": return "arrow.down.circle.fill"
        default: return "minus.circle.fill"
        }
    }

    private func trendColor(for trend: String) -> Color {
        switch trend {
        case "Improving": return .outcomeGood
        case "Declining": return .outcomeBad
        default: return .outcomeNeutral
        }
    }
}

#Preview {
    QuickStatsSection()
}
