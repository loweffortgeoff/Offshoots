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
    @Environment(DecisionStore.self) private var store

    private var pendingCount: Int {
        store.pendingDecisions.count
    }

    private var completedCount: Int {
        store.completedDecisions.count
    }

    private var totalCount: Int {
        store.decisions.count
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.offshootPrimary)

                Text("Your Decisions")
                    .font(.headline)
                    .foregroundStyle(Color.offshootPrimary)

                Spacer()
            }

            HStack(spacing: 20) {
                // Pending
                VStack(spacing: 4) {
                    Text("\(pendingCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.outcomePending)
                    Text("Pending")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                // Completed
                VStack(spacing: 4) {
                    Text("\(completedCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.outcomeGood)
                    Text("Completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                // Total
                VStack(spacing: 4) {
                    Text("\(totalCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.offshootPrimary)
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
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
