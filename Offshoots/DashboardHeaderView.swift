//
//  DashboardHeaderView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

//
//  DashboardHeaderView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct DashboardHeaderView: View {
    @EnvironmentObject var store: DecisionStore

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.offshootPrimary)

                Text("Decision Quality")
                    .font(.headline)
                    .foregroundStyle(Color.offshootPrimary)

                Spacer()
            }

            let score = AnalyticsEngine.decisionQualityScore(from: store.decisions)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(score)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.offshootPrimary, Color.offshootPrimary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Past 30 Days")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.offshootPrimary.opacity(0.08),
                                Color.offshootPrimary.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.offshootPrimary.opacity(0.15), lineWidth: 1.5)
            }
        )
        .shadow(color: Color.offshootPrimary.opacity(0.1), radius: 12, y: 6)
    }
}
