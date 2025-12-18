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

    private var isPending: Bool {
        decision.actual == nil
    }

    private var categoryText: String {
        decision.category.rawValue.capitalized
    }

    private var secondaryLine: String {
        if isPending {
            let dateText = decision.followUpDate.formatted(date: .abbreviated, time: .omitted)
            return "\(categoryText) • Review on \(dateText)"
        } else {
            let dateText = decision.followUpDate.formatted(date: .abbreviated, time: .omitted)
            return "\(categoryText) • Completed \(dateText)"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Left side: Text stack
            VStack(alignment: .leading, spacing: 4) {
                Text(decision.title)
                    .font(.body)
                    .fontWeight(isPending ? .medium : .semibold) // Slightly adjusted weight
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)

                Text(secondaryLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Right side: Outcome visuals
            if isPending {
                VStack(alignment: .trailing, spacing: 4) {
                    // Show expected icon faintly
                    OutcomeIcon(outcome: decision.expected)
                        .font(.system(size: 18))
                        .opacity(0.4) // Increased visibility slightly

                    Text("Pending")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.outcomePending.opacity(0.15)) // Theme color
                        )
                        .foregroundStyle(Color.outcomePending) // Text matches tint
                }
            } else if let actual = decision.actual {
                HStack(spacing: 6) {
                    OutcomeIcon(outcome: decision.expected)
                        .opacity(0.3)
                        .font(.system(size: 16))

                    OutcomeIcon(outcome: actual)
                        .font(.system(size: 20))
                }
            }
        }
        .padding(.vertical, 10) // Slightly more breathing room
        .padding(.horizontal, 12)
        .background(
            Group {
                if isPending {
                    // Subtle Goldenrod/Parchment tint for pending items
                    Color.outcomePending.opacity(0.08)
                } else {
                    Color.clear
                }
            }
        )
        .cornerRadius(12)
        // Add a subtle border to pending items to make them look like "cards"
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPending ? Color.outcomePending.opacity(0.15) : Color.clear, lineWidth: 1)
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
        ))

        DecisionRowView(decision: Decision(
            title: "Change app icon for Task(ed)",
            category: .work,
            expected: .good,
            actual: .good,
            followUpDate: Date()
        ))
    }
}
