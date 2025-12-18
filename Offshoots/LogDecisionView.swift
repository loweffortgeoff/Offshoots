//
//  LogDecisionView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct LogDecisionView: View {
    @EnvironmentObject var store: DecisionStore

    @State private var title = ""
    @State private var category: DecisionCategory = .work
    @State private var expected: DecisionOutcome = .neutral
    @State private var followUpDate = Date().addingTimeInterval(86400)
    @State private var showingSavedConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero section
                        VStack(spacing: 8) {
                            Image(systemName: "leaf.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(Color.offshootPrimary)

                            Text("Log a Decision")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.offshootPrimary)

                            Text("Track your choices and learn from outcomes")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        // Decision Input
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Decision", systemImage: "pencil.circle.fill")
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)

                            TextField("What decision are you making?", text: $title, axis: .vertical)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.offshootPrimary.opacity(0.2), lineWidth: 1)
                                )

                            Picker("Category", selection: $category) {
                                ForEach(DecisionCategory.allCases) { cat in
                                    Text(cat.rawValue.capitalized).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color.offshootPrimary)
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)

                        // Expected Outcome
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Expected Outcome", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)

                            Text("How do you think this will turn out?")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Picker("Outcome", selection: $expected) {
                                ForEach(DecisionOutcome.allCases) { outcome in
                                    HStack {
                                        OutcomeIcon(outcome: outcome)
                                        Text(outcome.rawValue.capitalized)
                                    }
                                    .tag(outcome)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)

                        // Follow-up Date
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Follow-Up", systemImage: "calendar.badge.clock")
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)

                            Text("When should you review this decision?")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            DatePicker("Review date", selection: $followUpDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .tint(Color.offshootPrimary)
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)

                        // Save Button
                        Button {
                            saveDecision()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Decision")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.offshootPrimary, Color.offshootPrimary.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundStyle(.white)
                            .cornerRadius(14)
                            .shadow(color: Color.offshootPrimary.opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .overlay(
                Group {
                    if showingSavedConfirmation {
                        SavedConfirmationView()
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            )
        }
    }

    private func saveDecision() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        store.createDecision(
            title: title,
            category: category,
            expected: expected,
            followUpDate: followUpDate
        )

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showingSavedConfirmation = true
        }

        title = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showingSavedConfirmation = false
            }
        }
    }
}

struct SavedConfirmationView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.white)

            Text("Decision Saved!")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.offshootPrimary)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        )
    }
}

#Preview {
    LogDecisionView()
        .environmentObject(DecisionStore())
}
