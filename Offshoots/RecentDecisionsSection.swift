//
//  RecentDecisionsSection.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct RecentDecisionsSection: View {
    @EnvironmentObject var store: DecisionStore
    @Binding var selectedTab: AppTab

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(Color.offshootPrimary)
                Text("Recent Decisions")
                    .font(.headline)
                    .foregroundStyle(Color.offshootPrimary)

                Spacer()

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
                            DecisionRowView(decision: decision)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct EmptyRecentDecisionsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
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
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

#Preview {
    RecentDecisionsSection(selectedTab: .constant(.dashboard))
        .environmentObject(DecisionStore())
}
