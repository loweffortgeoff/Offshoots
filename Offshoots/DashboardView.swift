//
//  DashboardView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct DashboardView: View {
    @Environment(DecisionStore.self) private var store
    @Binding var selectedTab: AppTab
    @Binding var logDraft: StarterSuggestion?
    /// The decision tapped in two-pane mode. See `DashboardSelection` for the fallback.
    @State private var selectedID: UUID?

    var body: some View {
        TwoPaneReader { arrangement in
            if arrangement != .single, #available(iOS 27.1, *) {
                let shown = DashboardSelection.current(
                    selectedID: selectedID,
                    ready: store.readyForReviewDecisions,
                    all: store.decisions
                )
                WidePanes(arrangement: arrangement) {
                    dashboard(selection: DashboardRowSelection(selectedID: shown?.id) { selectedID = $0.id })
                } secondary: {
                    NavigationStack {
                        if let shown {
                            DecisionDetailView(decision: shown)
                                .id(shown.id)
                        } else {
                            placeholder
                        }
                    }
                }
                // Pin what the pane shows, the default too. Otherwise marking the default
                // decision's outcome moves it out of Ready to Review, and the pane jumps to
                // the next one before the result banner shows.
                .onChange(of: shown?.id, initial: true) { _, id in
                    selectedID = id
                }
            } else {
                dashboard(selection: nil)
            }
        }
    }

    private func dashboard(selection: DashboardRowSelection?) -> some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.offshootPrimary.opacity(0.05),
                        Color.offshootBackground
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        DashboardHeaderView()

                        ReadyToReviewSection(selection: selection)

                        StarterSuggestionsSection(logDraft: $logDraft, selectedTab: $selectedTab)

                        QuickStatsSection()

                        RecentDecisionsSection(selectedTab: $selectedTab, selection: selection)

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("offshoots")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .offset(y: 10)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// The detail pane with no decisions yet
    private var placeholder: some View {
        ZStack {
            Color.offshootBackground
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.largeTitle)
                    .foregroundStyle(Color.offshootPrimary.opacity(0.6))
                    .accessibilityHidden(true)
                Text("Your decisions show here")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    DashboardView(selectedTab: .constant(.dashboard), logDraft: .constant(nil))
        .environment(DecisionStore())
        .environment(ReflectionCenter.make())
        .environment(ReflectionHistoryStore())
        .environment(HindsightAccess.make())
}
