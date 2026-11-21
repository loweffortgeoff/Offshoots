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
    @Environment(HindsightAccess.self) private var hindsight
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var notificationDelegate = NotificationDelegate.shared
    @State private var selectedTab: AppTab = .dashboard
    @State private var decisionsPath: [Decision] = []
    /// A starter suggestion on its way from the Dashboard to the Log form
    @State private var logDraft: StarterSuggestion?
    @State private var showHindsightReview = false
    @State private var showHindsightPurchase = false
    @State private var pendingHindsight = PendingHindsight()

    var body: some View {
        TabView(selection: $selectedTab) {
            FoldPane(ownsWideLayout: true) { DashboardView(selectedTab: $selectedTab, logDraft: $logDraft) }
                .tag(AppTab.dashboard)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }

            FoldPane(ownsWideLayout: true) { LogDecisionView(selectedTab: $selectedTab, draft: $logDraft, onOpenDecision: show) }
                .tag(AppTab.log)
                .tabItem {
                    Label("Log", systemImage: "plus.circle.fill")
                }

            FoldPane(ownsWideLayout: true) { DecisionsListView(path: $decisionsPath) }
                .tag(AppTab.decisions)
                .tabItem {
                    Label("Decisions", systemImage: "checklist")
                }

            FoldPane(ownsWideLayout: true) { AnalyticsView(showHindsightReview: $showHindsightReview) }
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
        .onOpenURL { url in
            notificationDelegate.pendingRoute = AppRoute(url: url)
        }
        // initial: true catches a tap that cold-launched the app before this view existed
        .onChange(of: notificationDelegate.pendingRoute, initial: true) { _, route in
            guard let route else { return }
            // Clear it so the same link or reminder tapped again still fires
            notificationDelegate.pendingRoute = nil
            handle(route)
        }
        // A Hindsight link that arrived before StoreKit answered
        .onChange(of: hindsight.entitlement?.hasResolvedOwnership) { _, resolved in
            guard resolved == true, pendingHindsight.isWaiting else { return }
            handle(.hindsight)
        }
        .sheet(isPresented: $showHindsightPurchase) {
            if let purchase = hindsight.purchase { HindsightPurchaseSheet(purchase: purchase) }
        }
    }

    private func handle(_ route: AppRoute) {
        // A purchase sheet left open from an earlier Hindsight link would hide the new destination
        if route != .hindsight {
            showHindsightPurchase = false
            pendingHindsight.note(route, target: nil)
        }
        switch route {
        case .log:
            selectedTab = .log
        case .decision(let id):
            selectedTab = .decisions
            decisionsPath = DecisionRoute.path(for: id, in: store.decisions)
        case .readyToReview:
            selectedTab = .decisions
            decisionsPath = []
        case .hindsight:
            let target = HindsightRouteTarget.resolve(
                hasResolvedOwnership: hindsight.entitlement?.hasResolvedOwnership ?? false,
                canCapture: hindsight.canCapture,
                entryCount: HindsightSummary.entries(from: store.decisions).count)
            pendingHindsight.note(route, target: target)
            switch target {
            // Insights is safe for owners and non-owners, so the tap shows something while StoreKit answers
            case .wait: selectedTab = .insights
            case .review:
                selectedTab = .insights
                showHindsightReview = true
            case .insights: selectedTab = .insights
            case .purchase: showHindsightPurchase = true
            }
        }
    }

    /// Opens a decision in the Decisions tab
    private func show(_ decision: Decision) {
        selectedTab = .decisions
        decisionsPath = [decision]
    }
}

#Preview {
    ContentView()
        .environment(DecisionStore())
        .environment(ReflectionCenter.make())
        .environment(ReflectionHistoryStore())
        .environment(HindsightAccess.make())
}
