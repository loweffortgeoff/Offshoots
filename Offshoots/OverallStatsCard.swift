//
//  OverallStatsCard.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct OverallStatsCard: View {
    let decisions: [Decision]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardTitle(title: "Overview", systemImage: "chart.pie.fill")

            let total = decisions.count
            let completed = decisions.filter { $0.actual != nil }.count
            let pending = total - completed
            let accuracy = AnalyticsEngine.predictionAccuracy(from: decisions)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2), spacing: 16) {
                StatBox(title: "Total", value: "\(total)", icon: "square.stack.3d.up.fill", color: .offshootPrimary)
                StatBox(title: "Completed", value: "\(completed)", icon: "checkmark.circle.fill", color: .outcomeGood)
                StatBox(title: "Pending", value: "\(pending)", icon: "hourglass", color: .outcomePending)
                StatBox(title: "Accuracy", value: "\(accuracy)%", icon: "target", color: .offshootPrimary)
            }
        }
        .padding(20)
        .background(Color.offshootCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}
