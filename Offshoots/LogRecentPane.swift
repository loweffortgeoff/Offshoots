//
//  LogRecentPane.swift
//  Offshoots
//

internal import SwiftUI

/// Recent decisions next to the Log form on a Duo with two panes: beside it in wide
/// landscape, below it when partly open in portrait. A tap opens the decision in the
/// Decisions tab, as a reminder tap does.
struct LogRecentPane: View {
    @Environment(DecisionStore.self) private var store
    let list: LogRecentList
    let onOpen: (Decision) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.offshootBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .accessibilityHidden(true)
                                .foregroundStyle(Color.offshootPrimary)
                            Text(heading)
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isHeader)

                        if decisions.isEmpty {
                            EmptyRecentDecisionsView()
                        } else {
                            VStack(spacing: 12) {
                                ForEach(decisions) { decision in
                                    Button {
                                        onOpen(decision)
                                    } label: {
                                        DecisionRowView(decision: decision, isReadyForReview: decision.isReadyForReview(asOf: store.today))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var heading: String {
        switch list {
        case .category(let category, _):
            "Recent in \(category.rawValue.capitalized)"
        case .all, .none:
            "Recent Decisions"
        }
    }

    private var decisions: [Decision] {
        switch list {
        case .category(_, let decisions), .all(let decisions):
            decisions
        case .none:
            []
        }
    }
}
