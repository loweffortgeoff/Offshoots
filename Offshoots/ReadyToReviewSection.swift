//
//  ReadyToReviewSection.swift
//  Offshoots
//

internal import SwiftUI

/// Dashboard callout for pending decisions whose review day has arrived.
/// Renders nothing when there's nothing to review.
struct ReadyToReviewSection: View {
    @Environment(DecisionStore.self) private var store

    var body: some View {
        let ready = store.readyForReviewDecisions

        if !ready.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(Color.offshootPrimary)
                    Text("Ready to Review")
                        .font(.headline)
                        .foregroundStyle(Color.offshootPrimary)

                    Spacer()

                    Text("\(ready.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.offshootPrimary.opacity(0.15)))
                        .foregroundStyle(Color.offshootPrimary)
                }

                VStack(spacing: 12) {
                    ForEach(ready) { decision in
                        NavigationLink {
                            DecisionDetailView(decision: decision)
                        } label: {
                            DecisionRowView(decision: decision, isReadyForReview: decision.isReadyForReview(asOf: store.today))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview {
    ReadyToReviewSection()
        .environment(DecisionStore())
}
