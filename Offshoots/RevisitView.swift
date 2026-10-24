//
//  RevisitView.swift
//  Offshoots
//

internal import SwiftUI

/// Re-rate a decision after its outcome was first marked, optionally
/// scheduling the next revisit so slow-burn decisions can be tracked over time.
struct RevisitView: View {
    @Environment(DecisionStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(ReflectionCenter.self) private var reflectionCenter

    @Environment(HindsightAccess.self) private var hindsightAccess
    @State private var hindsight: HindsightAnswer?
    @State private var ownershipBlocked = false

    let decision: Decision

    @FocusState private var isNoteFocused: Bool
    @State private var selectedOutcome: DecisionOutcome
    @State private var note: String = ""
    @State private var scheduleNext: Bool = false
    @State private var nextRevisitDate: Date = Date().addingTimeInterval(86400 * 30)

    init(decision: Decision) {
        self.decision = decision
        // Start from the latest assessment so "no change" is one tap
        _selectedOutcome = State(initialValue: decision.currentOutcome ?? .neutral)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.offshootBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Decision Title
                        VStack(spacing: 8) {
                            Text("Revisit Decision")
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
                            Label("How does it look now?", systemImage: "arrow.triangle.2.circlepath")
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)

                            if let current = decision.currentOutcome {
                                Text("Last rated \(current.shortLabel)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            OutcomePickerView(selection: $selectedOutcome)
                        }
                        .padding(16)
                        .background(Color.offshootCardBackground)
                        .cornerRadius(16)

                        HindsightCheckInSection(answer: $hindsight, access: hindsightAccess)

                        // Note
                        VStack(alignment: .leading, spacing: 12) {
                            Label("What Changed?", systemImage: "lightbulb.fill")
                                .font(.headline)
                                .foregroundStyle(Color.offshootPrimary)

                            Text("Optional - what you know now that you didn't before")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            TextField(hindsight == nil ? "What shifted since you last looked?" : "What would you keep or change?", text: $note, axis: .vertical)
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
                            if reflectionCenter.gate != .hidden {
                                CleanUpNoteRow(text: $note)
                            }
                        }
                        .padding(16)
                        .background(Color.offshootCardBackground)
                        .cornerRadius(16)

                        // Next revisit
                        NextRevisitPicker(
                            isOn: $scheduleNext,
                            date: $nextRevisitDate,
                            title: "Revisit Again",
                            caption: "Keep checking in on decisions that play out slowly",
                            toggleLabel: "Schedule another revisit"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    // A tap anywhere outside a control closes the keyboard.
                    // Controls (the text field, buttons) keep their own taps.
                    // The gesture is live only while the keyboard is up, so it
                    // never competes with the date picker for a tap.
                    .contentShape(Rectangle())
                    .gesture(
                        TapGesture().onEnded { isNoteFocused = false },
                        including: isNoteFocused ? .all : .subviews
                    )
                }
                .scrollDismissesKeyboard(.immediately)
                // Save stays in view: above the keyboard, and never at the screen edge.
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 8) {
                        if ownershipBlocked && hindsight != nil && !hindsightAccess.canCapture {
                            Text("Restore your purchase or clear the optional Hindsight answer before saving.")
                                .font(.callout).foregroundStyle(.secondary)
                                .accessibilityIdentifier("hindsightSaveBlocked")
                        }
                        Button {
                            saveRevisit()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Revisit")
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
        }
    }

    private func saveRevisit() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        guard hindsightAccess.performSave(answer: hindsight, save: { answer in
            store.addRevisit(
                id: decision.id,
                outcome: selectedOutcome,
                note: note,
                nextRevisitDate: scheduleNext ? nextRevisitDate : nil,
                hindsight: answer
            )
        }) else {
            ownershipBlocked = true
            return
        }

        dismiss()
    }
}

// MARK: - Next Revisit Picker

/// Toggle + date + quick intervals for scheduling a revisit.
/// Shared by Mark Outcome and Revisit.
struct NextRevisitPicker: View {
    @Binding var isOn: Bool
    @Binding var date: Date
    let title: String
    let caption: String
    let toggleLabel: String

    private let quickIntervals: [(days: Int, label: String)] = [
        (7, "1 week"),
        (30, "1 month"),
        (90, "3 months")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "calendar.badge.clock")
                .font(.headline)
                .foregroundStyle(Color.offshootPrimary)

            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle(toggleLabel, isOn: $isOn)
                .tint(Color.offshootPrimary)

            if isOn {
                DatePicker("Revisit date", selection: $date, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .tint(Color.offshootPrimary)

                HStack(spacing: 8) {
                    ForEach(quickIntervals, id: \.days) { interval in
                        Button {
                            date = Date().addingTimeInterval(Double(interval.days) * 86400)
                        } label: {
                            Text(interval.label)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.offshootPrimary.opacity(0.1))
                                .foregroundStyle(Color.offshootPrimary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.offshootCardBackground)
        .cornerRadius(16)
    }
}

#Preview {
    RevisitView(decision: Decision(
        title: "Take the new job offer",
        category: .work,
        expected: .good,
        actual: .good,
        followUpDate: Date()
    ))
    .environment(DecisionStore())
    .environment(ReflectionCenter.make())
    .environment(HindsightAccess.make())
}
