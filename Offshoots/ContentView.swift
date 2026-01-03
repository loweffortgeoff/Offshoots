//
//  ContentView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/7/25.
//

internal import SwiftUI

enum AppTab: Hashable {
    case dashboard
    case log
    case decisions
    case insights
    case settings
}

struct ContentView: View {
    @StateObject private var store = DecisionStore()
    @State private var deepLinkDecisionID: UUID?
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tag(AppTab.dashboard)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }

            LogDecisionView(selectedTab: $selectedTab)
                .tag(AppTab.log)
                .tabItem {
                    Label("Log", systemImage: "plus.circle.fill")
                }

            DecisionsListView()
                .tag(AppTab.decisions)
                .tabItem {
                    Label("Decisions", systemImage: "checklist")
                }

            AnalyticsView()
                .tag(AppTab.insights)
                .tabItem {
                    Label("Insights", systemImage: "brain.head.profile")
                }

            SettingsView()
                .tag(AppTab.settings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
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
