//
//  PredictionAccuracyCard.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI
internal import Charts

struct PredictionAccuracyCard: View {
    let decisions: [Decision]

    private var breakdown: AccuracyBreakdown {
        AnalyticsEngine.accuracyBreakdown(from: decisions)
    }

    private var accuracyData: [(label: String, count: Int, color: Color)] {
        [
            (label: "Correct", count: breakdown.correct, color: .outcomeGood),
            (label: "Incorrect", count: breakdown.incorrect, color: .outcomeBad)
        ].filter { $0.count > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Prediction Accuracy", systemImage: "target")
                .font(.headline)
                .foregroundStyle(Color.offshootPrimary)

            if breakdown.total == 0 {
                Text("No completed decisions to analyze")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
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
                            Text("\(breakdown.percent)%")
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
                            Text("\(breakdown.correct)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.outcomeGood)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Incorrect")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(breakdown.incorrect)")
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
