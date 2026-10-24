//
//  DecisionsListView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct DecisionsListView: View {
    @Environment(DecisionStore.self) private var store
    @Binding var path: [Decision]
    @Environment(\.foldPosture) private var foldPosture
    @State private var decisionToDelete: Decision?
    @State private var showDeleteAlert = false
    @State private var decisionToEdit: Decision?
    @ScaledMetric(relativeTo: .largeTitle) private var emptyIconSize: CGFloat = 60

    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing
            layout(arrangement: foldPosture.arrangement(width: screenWidth))
        }
        .onChange(of: store.decisions) { _, decisions in
            // A deleted decision must not stay in the path: the next rotation or fold change would push a detail for it
            let pruned = DecisionsSelection.pruned(path: path, in: decisions)
            if pruned != path {
                path = pruned
            }
        }
        .sheet(item: $decisionToEdit) { decision in
            EditDecisionView(decision: decision)
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
                Text("Are you sure you want to delete \"\(decision.title)\"? This action cannot be undone. Excerpts already saved in reflections will remain until you delete those readings.")
            }
        }
    }

    @ViewBuilder
    private func layout(arrangement: PaneArrangement) -> some View {
        if arrangement != .single, #available(iOS 27.1, *) {
            DecisionsSplitView(arrangement: arrangement, selection: DecisionsSelection.current(path: path, in: store.decisions)) {
                NavigationStack {
                    listContent(twoPanes: true, inlineTitle: arrangement == .stacked)
                }
            }
        } else {
            NavigationStack(path: $path) {
                listContent(twoPanes: false)
                    .navigationDestination(for: Decision.self) { decision in
                        DecisionDetailView(decision: decision)
                    }
            }
        }
    }

    /// `inlineTitle` is for stacked panes, which are only about 456 pt tall: a large title would take a fifth of the pane.
    private func listContent(twoPanes: Bool, inlineTitle: Bool = false) -> some View {
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
                            decisions: store.readyForReviewDecisions,
                            twoPanes: twoPanes
                        )

                        decisionSection(
                            "Upcoming",
                            icon: "hourglass.circle.fill",
                            color: .outcomePending,
                            decisions: store.upcomingDecisions,
                            twoPanes: twoPanes
                        )

                        decisionSection(
                            "History",
                            icon: "checkmark.circle.fill",
                            color: .offshootPrimary,
                            decisions: store.historyDecisions,
                            twoPanes: twoPanes
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle("Decisions")
        .navigationBarTitleDisplayMode(inlineTitle ? .inline : .large)
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
        decisions: [Decision],
        twoPanes: Bool
    ) -> some View {
        if !decisions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                customHeader(title, icon: icon, color: color)

                VStack(spacing: 12) {
                    ForEach(decisions) { decision in
                        row(decision, twoPanes: twoPanes)
                            .contextMenu {
                                Button("Edit", systemImage: "pencil") {
                                    decisionToEdit = decision
                                }
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    decisionToDelete = decision
                                    showDeleteAlert = true
                                }
                            }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ decision: Decision, twoPanes: Bool) -> some View {
        let rowView = DecisionRowView(decision: decision, isReadyForReview: decision.isReadyForReview(asOf: store.today))
        if twoPanes {
            let isSelected = path.last?.id == decision.id
            Button {
                path = [decision]
            } label: {
                rowView
            }
            .buttonStyle(.plain)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.offshootPrimary, lineWidth: 2)
                }
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            NavigationLink(value: decision) {
                rowView
            }
            .buttonStyle(.plain)
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
}

#Preview {
    DecisionsListView(path: .constant([]))
        .environment(DecisionStore())
        .environment(ReflectionCenter.make())
        .environment(HindsightAccess.make())
}

