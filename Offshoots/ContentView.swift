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
    @Environment(DecisionStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var notificationDelegate = NotificationDelegate.shared
    @State private var selectedTab: AppTab = .dashboard
    @State private var decisionsPath: [Decision] = []
    /// A starter suggestion on its way from the Dashboard to the Log form
    @State private var logDraft: StarterSuggestion?

    var body: some View {
        TabView(selection: $selectedTab) {
            FoldPane { DashboardView(selectedTab: $selectedTab, logDraft: $logDraft) }
                .tag(AppTab.dashboard)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }

            FoldPane { LogDecisionView(selectedTab: $selectedTab, draft: $logDraft) }
                .tag(AppTab.log)
                .tabItem {
                    Label("Log", systemImage: "plus.circle.fill")
                }

            FoldPane(ownsWideLayout: true) { DecisionsListView(path: $decisionsPath) }
                .tag(AppTab.decisions)
                .tabItem {
                    Label("Decisions", systemImage: "checklist")
                }

            FoldPane(ownsWideLayout: true) { AnalyticsView() }
                .tag(AppTab.insights)
                .tabItem {
                    Label("Insights", systemImage: "brain.head.profile")
                }

            FoldPane { SettingsView() }
                .tag(AppTab.settings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(Color.offshootPrimary)
        .readsFoldPosture()
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.refreshReviewState()
            }
        }
        // initial: true catches a tap that cold-launched the app before this view existed
        .onChange(of: notificationDelegate.pendingDecisionID, initial: true) { _, id in
            guard let id else { return }
            openDecision(id)
        }
    }

    private func openDecision(_ id: UUID) {
        // Clear it so tapping a reminder for the same decision again still fires
        notificationDelegate.pendingDecisionID = nil

        guard let target = store.decisions.first(where: { $0.id == id }) else { return }

        selectedTab = .decisions
        decisionsPath = [target]
    }
}

#Preview {
    ContentView()
        .environment(DecisionStore())
        .environment(ReflectionCenter.make())
}
