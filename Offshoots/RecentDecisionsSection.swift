//
//  RecentDecisionsSection.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct RecentDecisionsSection: View {
    @Environment(DecisionStore.self) private var store
    @Binding var selectedTab: AppTab
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility sizes "See All" moves under the title so neither breaks mid-word.
        let headerLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout())

        VStack(alignment: .leading, spacing: 16) {
            headerLayout {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(Color.offshootPrimary)
                    Text("Recent Decisions")
                        .font(.headline)
                        .foregroundStyle(Color.offshootPrimary)
                }

                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer()
                }

                if !store.decisions.isEmpty {
                    // Switch tabs rather than pushing a second NavigationStack
                    Button {
                        selectedTab = .decisions
                    } label: {
                        HStack(spacing: 4) {
                            Text("See All")
                                .font(.subheadline)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.offshootPrimary)
                    }
                }
            }

            if store.decisions.isEmpty {
                EmptyRecentDecisionsView()
            } else {
                VStack(spacing: 12) {
                    ForEach(store.decisions.prefix(3)) { decision in
                        NavigationLink {
                            DecisionDetailView(decision: decision)
                        } label: {
                            DecisionRowView(decision: decision, isReadyForReview: decision.isReadyForReview(asOf: store.today))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct EmptyRecentDecisionsView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 40
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: iconSize))
                .foregroundStyle(Color.offshootPrimary.opacity(0.3))

            Text("No decisions yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Log your first decision to start tracking")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.offshootCardBackground)
        .cornerRadius(16)
    }
}

#Preview {
    RecentDecisionsSection(selectedTab: .constant(.dashboard))
        .environment(DecisionStore())
}
