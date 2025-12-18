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
    @EnvironmentObject var store: DecisionStore
    @Environment(\.dismiss) private var dismiss
    let decision: Decision
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Hero Header
                    let heroColor: Color = {
                        if let actual = decision.actual {
                            return actual.themeColor.opacity(0.15)
                        } else {
                            return Color.outcomePending.opacity(0.15)
                        }
                    }()

                    let heroIcon: String = {
                        if let actual = decision.actual {
                            return actual == .good ? "leaf.fill" :
                                   actual == .neutral ? "minus.circle.fill" :
                                   "xmark.circle.fill"
                        } else {
                            return "hourglass"
                        }
                    }()

                    let heroIconColor: Color = {
                        if let actual = decision.actual {
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
                            .font(.system(size: 56))
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

                            HStack {
                                Label(decision.category.rawValue.capitalized, systemImage: "tag.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                if let actual = decision.actual {
                                    HStack(spacing: 6) {
                                        OutcomeIcon(outcome: actual)
                                            .font(.system(size: 18))
                                        Text(actual.rawValue.capitalized)
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
                                            .font(.system(size: 16))
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
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                        // Expected Outcome
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Expected Outcome", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)

                            HStack(spacing: 16) {
                                OutcomeIcon(outcome: decision.expected)
                                    .font(.system(size: 40))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(decision.expected.rawValue.capitalized)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(decision.expected.themeColor)

                                    Text("What you predicted")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
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
                                        .font(.system(size: 40))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(actual.rawValue.capitalized)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(actual.themeColor)

                                        Text("How it actually turned out")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                if decision.expected == actual {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trophy.fill")
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
                            .padding(20)
                            .background(Color(.secondarySystemGroupedBackground))
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
                            .padding(20)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
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
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                        // Complete Decision Actions (if pending)
                        if decision.actual == nil {
                            VStack(alignment: .leading, spacing: 16) {
                                Label("Mark Outcome", systemImage: "hand.tap.fill")
                                    .font(.headline)
                                    .foregroundStyle(Color.offshootPrimary)

                                Text("How did this decision actually turn out?")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                VStack(spacing: 12) {
                                    Button {
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                        store.resolveDecision(id: decision.id, actual: .good)
                                    } label: {
                                        HStack {
                                            OutcomeIcon(outcome: .good)
                                                .font(.system(size: 24))
                                            Text("Good")
                                                .fontWeight(.semibold)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }
                                        .padding()
                                        .background(Color.outcomeGood.opacity(0.1))
                                        .foregroundStyle(Color.outcomeGood)
                                        .cornerRadius(12)
                                    }

                                    Button {
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                        store.resolveDecision(id: decision.id, actual: .neutral)
                                    } label: {
                                        HStack {
                                            OutcomeIcon(outcome: .neutral)
                                                .font(.system(size: 24))
                                            Text("Neutral")
                                                .fontWeight(.semibold)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }
                                        .padding()
                                        .background(Color.outcomeNeutral.opacity(0.1))
                                        .foregroundStyle(Color.outcomeNeutral)
                                        .cornerRadius(12)
                                    }

                                    Button {
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                        store.resolveDecision(id: decision.id, actual: .bad)
                                    } label: {
                                        HStack {
                                            OutcomeIcon(outcome: .bad)
                                                .font(.system(size: 24))
                                            Text("Bad")
                                                .fontWeight(.semibold)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }
                                        .padding()
                                        .background(Color.outcomeBad.opacity(0.1))
                                        .foregroundStyle(Color.outcomeBad)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
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
