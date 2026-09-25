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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var pendingCount: Int {
        store.pendingDecisions.count
    }

    private var completedCount: Int {
        store.completedDecisions.count
    }

    private var totalCount: Int {
        store.decisions.count
    }

    /// Side by side normally; stacked at accessibility sizes so labels never break mid-word.
    private var statsLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(spacing: 20))
    }

    @ViewBuilder
    private var divider: some View {
        if !dynamicTypeSize.isAccessibilitySize {
            Divider()
                .frame(height: 40)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "leaf.circle.fill")
                    .accessibilityHidden(true)
                    .font(.title2)
                    .foregroundStyle(Color.offshootPrimary)

                Text("Your Decisions")
                    .font(.headline)
                    .foregroundStyle(Color.offshootPrimary)

                Spacer()
            }

            statsLayout {
                HeaderStat(value: pendingCount, label: "Pending", color: .outcomePending)
                divider
                HeaderStat(value: completedCount, label: "Completed", color: .outcomeGood)
                divider
                HeaderStat(value: totalCount, label: "Total", color: .offshootPrimary)
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

private struct HeaderStat: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
