//
//  OutcomeDistributionCard.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI
internal import Charts

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
