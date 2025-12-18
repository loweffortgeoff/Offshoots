//
//  ContentView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/7/25.
//

internal import SwiftUI

struct ContentView: View {
    @StateObject private var store = DecisionStore()
    @State private var deepLinkDecisionID: UUID?

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }

            LogDecisionView()
                .tabItem {
                    Label("Log", systemImage: "plus.circle.fill")
                }

            DecisionsListView()
                .tabItem {
                    Label("Decisions", systemImage: "checklist")
                }

            AnalyticsView()
                .tabItem {
                    Label("Insights", systemImage: "brain.head.profile")
                }
        }
        .tint(Color.offshootPrimary)
        .environmentObject(store)
        .onReceive(NotificationCenter.default.publisher(for: .openDecision)) { notification in
            if let id = notification.object as? UUID {
                deepLinkDecisionID = id
            }
        }
        .onChange(of: deepLinkDecisionID) { oldValue, newValue in
            guard let newValue else { return }
            handleDeepLink(newValue)
        }
    }

    private func handleDeepLink(_ id: UUID) {
        // Let's leverage your store to find the decision
        if let target = store.decisions.first(where: { $0.id == id }) {
            // Navigate to Decisions tab & trigger its destination
            // We'll add a route binding in DecisionsListView next
            NotificationCenter.default.post(
                name: .navigateToDecision,
                object: target
            )
        }
    }
}

#Preview {
    ContentView()
}
