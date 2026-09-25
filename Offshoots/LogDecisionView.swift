//
//  LogDecisionView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct LogDecisionView: View {
    @Environment(DecisionStore.self) private var store
    @Binding var selectedTab: AppTab
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isNotesFocused: Bool

    @State private var title = ""
    @State private var notes = ""
    @State private var category: DecisionCategory = .work
    @State private var stakes: DecisionStakes = .medium
    @State private var expected: DecisionOutcome = .neutral
    @State private var followUpDate = Date().addingTimeInterval(86400)
    @State private var showingSavedConfirmation = false

    private var trimmedNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Earliest selectable review date; a past date would schedule a reminder that never fires
    private var earliestReviewDate: Date {
        Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.offshootBackground
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissKeyboard()
                    }

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
                                .focused($isTitleFocused)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color.offshootBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.offshootPrimary.opacity(0.2), lineWidth: 1)
                                )
                                .submitLabel(.done)
                                .onSubmit {
                                    isTitleFocused = false
                                }

                            Picker("Category", selection: $category) {
                                ForEach(DecisionCategory.allCases) { cat in
                                    Text(cat.rawValue.capitalized).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color.offshootPrimary)
                        }
                        .padding(16)
                        .background(Color.offshootCardBackground)
                        .cornerRadius(16)

                        // Notes
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Notes", systemImage: "note.text")
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)

                            Text("Optional - what you know and why you're leaning this way")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            TextField("What's driving this decision?", text: $notes, axis: .vertical)
                                .focused($isNotesFocused)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color.offshootBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.offshootPrimary.opacity(0.2), lineWidth: 1)
                                )
                                .lineLimit(3...6)
                        }
                        .padding(16)
                        .background(Color.offshootCardBackground)
                        .cornerRadius(16)

                        // Stakes
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Stakes", systemImage: "flag.fill")
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)

                            Text("How significant is this decision?")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Picker("Stakes", selection: $stakes) {
                                ForEach(DecisionStakes.allCases) { stake in
                                    Text(stake.label).tag(stake)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(16)
                        .background(Color.offshootCardBackground)
                        .cornerRadius(16)

                        // Expected Outcome
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Expected Outcome", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)

                            Text("How do you think this will turn out?")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            OutcomePickerView(selection: $expected)
                        }
                        .padding(16)
                        .background(Color.offshootCardBackground)
                        .cornerRadius(16)

                        // Follow-up Date
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Follow-Up", systemImage: "calendar.badge.clock")
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)

                            Text("When should you review this decision?")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            DatePicker("Review date", selection: $followUpDate, in: earliestReviewDate..., displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .tint(Color.offshootPrimary)
                        }
                        .padding(16)
                        .background(Color.offshootCardBackground)
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
                            .background(Color.offshootPrimary)
                            .foregroundStyle(Color.offshootOnPrimary)
                            .cornerRadius(14)
                            .shadow(color: Color.offshootPrimary.opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                    .fontWeight(.semibold)
                }
            }
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

    private func dismissKeyboard() {
        isTitleFocused = false
        isNotesFocused = false
    }

    private func saveDecision() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        store.createDecision(
            title: title,
            category: category,
            stakes: stakes,
            expected: expected,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            followUpDate: followUpDate
        )

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showingSavedConfirmation = true
        }

        // Reset form
        title = ""
        notes = ""
        category = .work
        stakes = .medium
        expected = .neutral
        followUpDate = Date().addingTimeInterval(86400)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showingSavedConfirmation = false
                selectedTab = .dashboard
            }
        }
    }
}

struct SavedConfirmationView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.offshootOnPrimary)

            Text("Decision Saved!")
                .font(.headline)
                .foregroundStyle(Color.offshootOnPrimary)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.offshootPrimary)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        )
    }
}

// MARK: - Outcome Picker View

struct OutcomePickerView: View {
    @Binding var selection: DecisionOutcome

    var body: some View {
        HStack(spacing: 8) {
            ForEach(DecisionOutcome.allCases) { outcome in
                OutcomeButton(
                    outcome: outcome,
                    isSelected: selection == outcome
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selection = outcome
                    }
                }
            }
        }
    }
}

struct OutcomeButton: View {
    let outcome: DecisionOutcome
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                OutcomeIcon(outcome: outcome)
                    .font(.system(size: isSelected ? 24 : 20))

                Text(outcome.compactLabel)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? outcome.themeColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? outcome.themeColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? outcome.themeColor : .secondary)
    }
}

#Preview {
    LogDecisionView(selectedTab: .constant(.log))
        .environment(DecisionStore())
}
