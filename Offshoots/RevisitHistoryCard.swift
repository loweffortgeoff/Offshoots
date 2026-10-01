//
//  RevisitHistoryCard.swift
//  Offshoots
//

internal import SwiftUI

/// Timeline of re-ratings, each shown against the assessment before it
struct RevisitHistoryCard: View {
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
