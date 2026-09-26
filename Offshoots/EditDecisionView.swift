//
//  EditDecisionView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 1/3/26.
//

internal import SwiftUI

struct EditDecisionView: View {
    @Environment(DecisionStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isNotesFocused: Bool

    let decision: Decision

    @State private var title: String
    @State private var category: DecisionCategory
    @State private var stakes: DecisionStakes
    @State private var expected: DecisionOutcome
    @State private var followUpDate: Date
    @State private var notes: String

    /// Blocks moving the review into the past, but keeps an already-overdue date selectable
    private var earliestReviewDate: Date {
        let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        return min(decision.followUpDate, tomorrow)
    }

    init(decision: Decision) {
        self.decision = decision
        _title = State(initialValue: decision.title)
        _category = State(initialValue: decision.category)
        _stakes = State(initialValue: decision.stakes)
        _expected = State(initialValue: decision.expected)
        _followUpDate = State(initialValue: decision.followUpDate)
        _notes = State(initialValue: decision.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.offshootBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
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

                        // Stakes (only editable if pending)
                        if decision.actual == nil {
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
                        }

                        // Expected Outcome (only editable if pending)
                        if decision.actual == nil {
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
                        }

                        // Follow-up Date (only editable if pending)
                        if decision.actual == nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Follow-Up", systemImage: "calendar.badge.clock")
                                    .font(.headline)
                                    .foregroundStyle(Color.offshootPrimary)

                                Text("When should you review this decision?")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ReviewDatePresetRow(date: $followUpDate)

                                DatePicker("Review date", selection: $followUpDate, in: earliestReviewDate..., displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .tint(Color.offshootPrimary)
                            }
                            .padding(16)
                            .background(Color.offshootCardBackground)
                            .cornerRadius(16)
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Notes", systemImage: "note.text")
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)

                            TextField("Add any additional notes...", text: $notes, axis: .vertical)
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    // A tap anywhere outside a control closes the keyboard.
                    // Controls (the text fields, buttons) keep their own taps.
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissKeyboard()
                    }
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationTitle("Edit Decision")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func dismissKeyboard() {
        isTitleFocused = false
        isNotesFocused = false
    }

    private func saveChanges() {
        var updatedDecision = decision
        updatedDecision.title = title.trimmingCharacters(in: .whitespaces)
        updatedDecision.category = category
        updatedDecision.notes = notes.isEmpty ? nil : notes

        // Only update these if decision is still pending
        if decision.actual == nil {
            updatedDecision.stakes = stakes
            updatedDecision.expected = expected
            updatedDecision.followUpDate = followUpDate
        }

        store.update(updatedDecision)

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        dismiss()
    }
}

#Preview {
    EditDecisionView(decision: Decision(
        title: "Test Decision",
        category: .work,
        expected: .good,
        followUpDate: Date().addingTimeInterval(86400 * 7)
    ))
    .environment(DecisionStore())
}
