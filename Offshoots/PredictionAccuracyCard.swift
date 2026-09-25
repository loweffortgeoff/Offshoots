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
