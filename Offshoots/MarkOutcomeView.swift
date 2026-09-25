//
//  MarkOutcomeView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 1/3/26.
//

internal import SwiftUI

struct MarkOutcomeView: View {
    @Environment(DecisionStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let decision: Decision

    @FocusState private var isNoteFocused: Bool
    @State private var selectedOutcome: DecisionOutcome = .neutral
    @State private var reflection: String = ""
    @State private var setFollowUpReminder: Bool = false
    @State private var secondaryFollowUpDate: Date = Date().addingTimeInterval(86400 * 30) // 30 days default

    private let reflectionHints = [
        "What surprised you about the outcome?",
        "What would you do differently next time?",
        "What did you learn from this decision?",
        "Were there warning signs you missed?",
        "What factors influenced the outcome?"
    ]

    @State private var currentHint: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.offshootBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Decision Title
                        VStack(spacing: 8) {
                            Text("Mark Outcome")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.offshootPrimary)

                            Text(decision.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)

                        // Outcome Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Label("How did it turn out?", systemImage: "checkmark.seal.fill")
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)

                            OutcomePickerView(selection: $selectedOutcome)
                        }
                        .padding(16)
                        .background(Color.offshootCardBackground)
                        .cornerRadius(16)

                        // Reflection
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Reflection", systemImage: "lightbulb.fill")
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)

                            Text("Optional - capture your thoughts")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            TextField(currentHint, text: $reflection, axis: .vertical)
                                .focused($isNoteFocused)
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

                        // Follow-up Reminder
                        NextRevisitPicker(
                            isOn: $setFollowUpReminder,
                            date: $secondaryFollowUpDate,
                            title: "Revisit Later",
                            caption: "Set a reminder to check if your assessment still holds",
                            toggleLabel: "Schedule a follow-up"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    // A tap anywhere outside a control closes the keyboard.
                    // Controls (the text field, buttons) keep their own taps.
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isNoteFocused = false
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                // Save stays in view: above the keyboard, and never at the screen edge.
                .safeAreaInset(edge: .bottom) {
                    Button {
                        saveOutcome()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Outcome")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.offshootPrimary)
                        .foregroundStyle(Color.offshootOnPrimary)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.offshootBackground)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isNoteFocused = false
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                currentHint = reflectionHints.randomElement() ?? reflectionHints[0]
            }
        }
    }

    private func saveOutcome() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        store.resolveDecision(
            id: decision.id,
            actual: selectedOutcome,
            reflection: reflection.isEmpty ? nil : reflection,
            secondaryFollowUpDate: setFollowUpReminder ? secondaryFollowUpDate : nil
        )

        dismiss()
    }
}

#Preview {
    MarkOutcomeView(decision: Decision(
        title: "Test Decision",
        category: .work,
        expected: .good,
        followUpDate: Date()
    ))
    .environment(DecisionStore())
}
