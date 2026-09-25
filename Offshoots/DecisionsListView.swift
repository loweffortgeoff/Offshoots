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
    @Environment(DecisionStore.self) private var store
    @Binding var path: NavigationPath
    @State private var decisionToDelete: Decision?
    @State private var showDeleteAlert = false
    @ScaledMetric(relativeTo: .largeTitle) private var emptyIconSize: CGFloat = 60

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.offshootBackground
                    .ignoresSafeArea()

                if store.decisions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            decisionSection(
                                "Ready to Review",
                                icon: "bell.badge.fill",
                                color: .offshootPrimary,
                                decisions: store.readyForReviewDecisions
                            )

                            decisionSection(
                                "Upcoming",
                                icon: "hourglass.circle.fill",
                                color: .outcomePending,
                                decisions: store.upcomingDecisions
                            )

                            decisionSection(
                                "History",
                                icon: "checkmark.circle.fill",
                                color: .offshootPrimary,
                                decisions: store.historyDecisions
                            )
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
                        .frame(width: emptyIconSize * 2, height: emptyIconSize * 2)

                    Image(systemName: "leaf.circle.fill")
                        .accessibilityHidden(true)
                        .font(.system(size: emptyIconSize))
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

    @ViewBuilder
    private func decisionSection(
        _ title: String,
        icon: String,
        color: Color,
        decisions: [Decision]
    ) -> some View {
        if !decisions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                customHeader(title, icon: icon, color: color)

                VStack(spacing: 12) {
                    ForEach(decisions) { decision in
                        NavigationLink(value: decision) {
                            DecisionRowView(decision: decision, isReadyForReview: decision.isReadyForReview(asOf: store.today))
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

    private func customHeader(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .accessibilityHidden(true)
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
    DecisionsListView(path: .constant(NavigationPath()))
        .environment(DecisionStore())
}

