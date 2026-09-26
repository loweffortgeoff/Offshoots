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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var breakdown: AccuracyBreakdown {
        AnalyticsEngine.accuracyBreakdown(from: decisions)
    }

    private var accuracyData: [(label: String, count: Int, color: Color)] {
        [
            (label: "Correct", count: breakdown.correct, color: .outcomeGood),
            (label: "Close", count: breakdown.close, color: .outcomeNeutral),
            (label: "Missed", count: breakdown.incorrect, color: .outcomeBad)
        ].filter { $0.count > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardTitle(title: "Prediction Accuracy", systemImage: "target")

            if breakdown.total == 0 {
                Text("Mark your first outcome to see this.")
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
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .foregroundStyle(Color.offshootPrimary)

                            Text("Accurate")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        // The labels sit inside a fixed ring, so they stop growing past xxxLarge.
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    }
                    .frame(maxWidth: .infinity)

                    let countsLayout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                        : AnyLayout(HStackLayout())
                    countsLayout {
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
                            Text("Close")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(breakdown.close)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.outcomeNeutral)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Missed")
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

                    Text("Correct is an exact match. Close is one step off. Missed is two or more.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.offshootCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}
