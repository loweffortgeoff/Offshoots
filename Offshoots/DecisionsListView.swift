//
//  DecisionsListView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

//
//  DecisionsListView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

//
//  DecisionsListView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct DecisionsListView: View {
    @EnvironmentObject var store: DecisionStore
    @State private var navigationPath = NavigationPath()
    @State private var decisionToDelete: Decision?
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if store.decisions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            let pending = store.pendingDecisions
                            let completed = store.completedDecisions

                            if !pending.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    customHeader("Pending", icon: "hourglass.circle.fill", color: .outcomePending)

                                    VStack(spacing: 12) {
                                        ForEach(pending) { decision in
                                            NavigationLink(value: decision) {
                                                DecisionRowView(decision: decision)
                                            }
                                            .buttonStyle(.plain)
                                            .onLongPressGesture {
                                                decisionToDelete = decision
                                                showDeleteAlert = true
                                            }
                                        }
                                    }
                                }
                            }

                            if !completed.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    customHeader("History", icon: "checkmark.circle.fill", color: .offshootPrimary)

                                    VStack(spacing: 12) {
                                        ForEach(completed) { decision in
                                            NavigationLink(value: decision) {
                                                DecisionRowView(decision: decision)
                                            }
                                            .buttonStyle(.plain)
                                            .onLongPressGesture {
                                                decisionToDelete = decision
                                                showDeleteAlert = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    }
                }
            }
            .navigationDestination(for: Decision.self) { decision in
                DecisionDetailView(decision: decision)
            }
            .navigationTitle("Decisions")
            .navigationBarTitleDisplayMode(.large)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToDecision)) { notification in
            if let decision = notification.object as? Decision {
                navigationPath = NavigationPath()
                navigationPath.append(decision)
            }
        }
        .alert("Delete Decision?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                decisionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let decision = decisionToDelete {
                    store.delete(decision)
                    decisionToDelete = nil
                }
            }
        } message: {
            if let decision = decisionToDelete {
                Text("Are you sure you want to delete \"\(decision.title)\"? This action cannot be undone.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.offshootPrimary.opacity(0.1), Color.offshootPrimary.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.offshootPrimary.opacity(0.6))
                }

                VStack(spacing: 8) {
                    Text("No Decisions Yet")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.offshootPrimary)

                    Text("Start tracking your decisions to learn from your outcomes and improve your decision-making skills.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func customHeader(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.headline)
                .foregroundStyle(color)
        }
    }

    // MARK: - Delete Helpers
    
    private func deletePending(at offsets: IndexSet) {
        let items = store.pendingDecisions
        for index in offsets {
            store.delete(items[index])
        }
    }

    private func deleteCompleted(at offsets: IndexSet) {
        let items = store.completedDecisions
        for index in offsets {
            store.delete(items[index])
        }
    }
}

#Preview {
    DecisionsListView()
        .environmentObject(DecisionStore())
}

extension Notification.Name {
    static let navigateToDecision = Notification.Name("navigateToDecision")
}
