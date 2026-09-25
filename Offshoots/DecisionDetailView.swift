//
//  DecisionDetailView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

//
//  DecisionDetailView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct DecisionDetailView: View {
    @Environment(DecisionStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .largeTitle) private var heroIconSize: CGFloat = 56
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var outcomeIconSize: CGFloat = 40
    private let decisionID: UUID
    private let snapshot: Decision
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var showMarkOutcomeSheet = false
    @State private var showRevisitSheet = false

    init(decision: Decision) {
        self.decisionID = decision.id
        self.snapshot = decision
    }

    /// Live copy from the store so edits and outcomes show immediately;
    /// falls back to the snapshot while the view dismisses after a delete.
    private var decision: Decision {
        store.decisions.first { $0.id == decisionID } ?? snapshot
    }

    var body: some View {
        ZStack {
            Color.offshootBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Hero Header (reflects the latest assessment)
                    let heroColor: Color = {
                        if let actual = decision.currentOutcome {
                            return actual.themeColor.opacity(0.15)
                        } else {
                            return Color.outcomePending.opacity(0.15)
                        }
                    }()

                    let heroIcon: String = {
                        if let actual = decision.currentOutcome {
                            switch actual {
                            case .veryGood: return "star.fill"
                            case .good: return "leaf.fill"
                            case .neutral: return "minus.circle.fill"
                            case .bad: return "xmark.circle.fill"
                            case .veryBad: return "exclamationmark.triangle.fill"
                            }
                        } else {
                            return "hourglass"
                        }
                    }()

                    let heroIconColor: Color = {
                        if let actual = decision.currentOutcome {
                            return actual.themeColor
                        } else {
                            return Color.outcomePending
                        }
                    }()

                    ZStack {
                        LinearGradient(
                            colors: [heroColor, heroColor.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Image(systemName: heroIcon)
                            .accessibilityHidden(true)
                            .font(.system(size: heroIconSize))
                            .foregroundStyle(heroIconColor.opacity(0.4))
                    }
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)

                    // Content
                    VStack(alignment: .leading, spacing: 24) {
                        // Title Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text(decision.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.offshootPrimary)

                            // At accessibility sizes the category, stakes and status stack.
                            let metaLayout = dynamicTypeSize.isAccessibilitySize
                                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                                : AnyLayout(HStackLayout())
                            metaLayout {
                                Label(decision.category.rawValue.capitalized, systemImage: "tag.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Label(decision.stakes.label, systemImage: "flag.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if !dynamicTypeSize.isAccessibilitySize {
                                    Spacer()
                                }

                                if let actual = decision.currentOutcome {
                                    HStack(spacing: 6) {
                                        OutcomeIcon(outcome: actual)
                                            .font(.body)
                                            .accessibilityHidden(true)
                                        Text(actual.shortLabel)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(actual.themeColor)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(actual.themeColor.opacity(0.1))
                                    .cornerRadius(12)
                                } else {
                                    HStack(spacing: 6) {
                                        Image(systemName: "hourglass")
                                            .accessibilityHidden(true)
                                            .font(.callout)
                                        Text("Pending")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(Color.outcomePending)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.outcomePending.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color.offshootCardBackground)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                        // Notes (context captured when logging or editing)
                        if let notes = decision.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Notes", systemImage: "note.text")
                                    .font(.headline)
                                    .foregroundStyle(Color.offshootPrimary)

                                Text(notes)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color.offshootCardBackground)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                        }

                        // Expected Outcome
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Expected Outcome", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)

                            HStack(spacing: 16) {
                                OutcomeIcon(outcome: decision.expected)
                                    .font(.system(size: outcomeIconSize))
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(decision.expected.shortLabel)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(decision.expected.themeColor)

                                    Text("What you predicted")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color.offshootCardBackground)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                        // Actual Outcome (if completed)
                        if let actual = decision.actual {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Actual Outcome", systemImage: "checkmark.seal.fill")
                                    .font(.headline)
                                    .foregroundStyle(Color.offshootPrimary)

                                HStack(spacing: 16) {
                                    OutcomeIcon(outcome: actual)
                                        .font(.system(size: outcomeIconSize))
                                        .accessibilityHidden(true)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(actual.shortLabel)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(actual.themeColor)

                                        Text(decision.revisits.isEmpty ? "How it actually turned out" : "How it first turned out")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                if decision.expected == actual {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trophy.fill")
                                            .accessibilityHidden(true)
                                            .foregroundStyle(.yellow)
                                        Text("You predicted correctly!")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(Color.offshootPrimary)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color.offshootCardBackground)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                        }

                        // Reflection
                        if let reflection = decision.reflection {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Reflection", systemImage: "lightbulb.fill")
                                    .font(.headline)
                                    .foregroundStyle(Color.offshootPrimary)

                                Text(reflection)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color.offshootCardBackground)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                        }

                        // Revisit history
                        if !decision.revisits.isEmpty {
                            RevisitHistoryCard(decision: decision)
                        }

                        // Follow-up Date
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Follow-Up Date", systemImage: "calendar")
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)

                            Text(decision.followUpDate.formatted(date: .long, time: .omitted))
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color.offshootCardBackground)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                        // Next revisit date (if set)
                        if let secondaryDate = decision.secondaryFollowUpDate {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Next Revisit", systemImage: "calendar.badge.clock")
                                    .font(.headline)
                                    .foregroundStyle(Color.offshootPrimary)

                                Text(secondaryDate.formatted(date: .long, time: .omitted))
                                    .font(.body)
                                    .foregroundStyle(.secondary)

                                Text("Scheduled to revisit this decision")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color.offshootCardBackground)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                        }

                        // Complete Decision Actions (if pending)
                        if decision.actual == nil {
                            Button {
                                showMarkOutcomeSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Mark Outcome")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.offshootPrimary)
                                .foregroundStyle(Color.offshootOnPrimary)
                                .cornerRadius(14)
                                .shadow(color: Color.offshootPrimary.opacity(0.3), radius: 8, y: 4)
                            }
                        } else {
                            // Revisit is always available; emphasized once it's due
                            let isDue = decision.isReadyForReview(asOf: store.today)
                            Button {
                                showRevisitSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Revisit Decision")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isDue ? Color.offshootPrimary : Color.offshootPrimary.opacity(0.1))
                                .foregroundStyle(isDue ? Color.offshootOnPrimary : Color.offshootPrimary)
                                .cornerRadius(14)
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditSheet = true
                } label: {
                    Text("Edit")
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditDecisionView(decision: decision)
        }
        .sheet(isPresented: $showMarkOutcomeSheet) {
            MarkOutcomeView(decision: decision)
        }
        .sheet(isPresented: $showRevisitSheet) {
            RevisitView(decision: decision)
        }
        .alert("Delete Decision?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                store.delete(decision)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \"\(decision.title)\"? This action cannot be undone.")
        }
    }
}

// MARK: - Revisit History

/// Timeline of re-ratings, each shown against the assessment before it
private struct RevisitHistoryCard: View {
    let decision: Decision

    /// Pairs each revisit with the outcome it replaced
    private var entries: [(revisit: Revisit, previous: DecisionOutcome?)] {
        decision.revisits.enumerated().map { index, revisit in
            let previous = index == 0 ? decision.actual : decision.revisits[index - 1].outcome
            return (revisit: revisit, previous: previous)
        }
    }

    /// "Bad to Good" when the rating changed, otherwise just the rating.
    private func revisitChangeLabel(_ entry: (revisit: Revisit, previous: DecisionOutcome?)) -> String {
        if let previous = entry.previous, previous != entry.revisit.outcome {
            return "\(previous.shortLabel) to \(entry.revisit.outcome.shortLabel)"
        }
        return entry.revisit.outcome.shortLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Revisits", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)
                .foregroundStyle(Color.offshootPrimary)

            ForEach(entries, id: \.revisit.id) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        if let previous = entry.previous, previous != entry.revisit.outcome {
                            OutcomeIcon(outcome: previous)
                                .font(.callout)
                                .opacity(0.4)
                                .accessibilityHidden(true)
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }

                        OutcomeIcon(outcome: entry.revisit.outcome)
                            .font(.body)
                            .accessibilityHidden(true)

                        Text(entry.revisit.outcome.shortLabel)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(entry.revisit.outcome.themeColor)
                            .accessibilityLabel(revisitChangeLabel(entry))

                        Spacer()

                        Text(entry.revisit.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let note = entry.revisit.note {
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }

                if entry.revisit.id != decision.revisits.last?.id {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.offshootCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}
