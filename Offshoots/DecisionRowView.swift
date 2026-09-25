//
//  DecisionRowView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

//
//  DecisionRowView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct DecisionRowView: View {
    let decision: Decision
    /// Passed in so the row redraws when the store's day moves forward
    let isReadyForReview: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isPending: Bool {
        decision.actual == nil
    }

    private var categoryText: String {
        decision.category.rawValue.capitalized
    }

    private var secondaryLine: String {
        if isReadyForReview {
            return "\(categoryText) • Ready to \(isPending ? "review" : "revisit")"
        } else if isPending {
            let dateText = decision.followUpDate.formatted(date: .abbreviated, time: .omitted)
            return "\(categoryText) • Review on \(dateText)"
        } else {
            // Decisions resolved before resolvedAt existed fall back to their review date
            let dateText = (decision.resolvedAt ?? decision.followUpDate).formatted(date: .abbreviated, time: .omitted)
            return "\(categoryText) • Completed \(dateText)"
        }
    }

    /// Brand accent once the review day arrives; neutral sand while waiting
    private var statusColor: Color {
        isReadyForReview ? .offshootPrimary : .outcomePending
    }

    /// At accessibility sizes the row stacks, so the title gets the full width.
    private var isStacked: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private func statusPill(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.15)) // Theme color
            )
            .foregroundStyle(statusColor) // Text matches tint
    }

    var body: some View {
        let rowLayout = isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        let statusLayout = isStacked
            ? AnyLayout(HStackLayout(spacing: 8))
            : AnyLayout(VStackLayout(alignment: .trailing, spacing: 4))

        rowLayout {
            // Left side: Text stack
            VStack(alignment: .leading, spacing: 4) {
                Text(decision.title)
                    .font(.body)
                    .fontWeight(isPending ? .medium : .semibold) // Slightly adjusted weight
                    .foregroundStyle(Color.primary)
                    .lineLimit(isStacked ? nil : 2)

                Text(secondaryLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !isStacked {
                Spacer()
            }

            // Right side: Outcome visuals
            if isPending {
                statusLayout {
                    // Show expected icon faintly
                    OutcomeIcon(outcome: decision.expected)
                        .font(.body)
                        .opacity(0.4) // Increased visibility slightly
                        .accessibilityLabel("Expected \(decision.expected.shortLabel)")

                    statusPill(isReadyForReview ? "Review" : "Pending")
                }
            } else if let current = decision.currentOutcome {
                statusLayout {
                    HStack(spacing: 6) {
                        OutcomeIcon(outcome: decision.expected)
                            .opacity(0.3)
                            .font(.callout)

                        OutcomeIcon(outcome: current)
                            .font(.title3)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Expected \(decision.expected.shortLabel), turned out \(current.shortLabel)")

                    // Due for a revisit: same pill as a pending review
                    if isReadyForReview {
                        statusPill("Revisit")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10) // Slightly more breathing room
        .padding(.horizontal, 12)
        .background(
            Group {
                if isPending || isReadyForReview {
                    // Subtle tint for items waiting on you
                    statusColor.opacity(0.08)
                } else {
                    Color.clear
                }
            }
        )
        .cornerRadius(12)
        // Add a subtle border to pending items to make them look like "cards"
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPending || isReadyForReview ? statusColor.opacity(0.15) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    List {
        DecisionRowView(decision: Decision(
            title: "Buy refurbished Mac mini or new?",
            category: .money,
            expected: .good,
            actual: nil,
            followUpDate: Date().addingTimeInterval(86400 * 3)
        ), isReadyForReview: false)

        DecisionRowView(decision: Decision(
            title: "Change app icon for Task(ed)",
            category: .work,
            expected: .good,
            actual: .good,
            followUpDate: Date()
        ), isReadyForReview: false)
    }
}
