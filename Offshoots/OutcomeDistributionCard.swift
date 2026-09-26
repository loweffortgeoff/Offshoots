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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var totalCompleted: Int {
        decisions.filter { $0.actual != nil }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardTitle(title: "Outcomes", systemImage: "chart.pie.fill")

            if totalCompleted == 0 {
                Text("Mark your first outcome to see this.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                let shares = AnalyticsEngine.outcomeDistribution(from: decisions)
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(spacing: 20))
                    : AnyLayout(HStackLayout(spacing: 20))
                layout {
                    Chart(shares, id: \.outcome) { item in
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
                        ForEach(shares, id: \.outcome) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.outcome.themeColor)
                                    .frame(width: 8, height: 8)
                                Text(item.outcome.compactLabel)
                                    .font(.caption)
                                Spacer()
                                Text("\(item.percent)%")
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.offshootCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}
