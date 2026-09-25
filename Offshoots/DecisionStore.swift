//
//  DecisionStore.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

//
//  DecisionStore.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

import Foundation
import Observation
internal import SwiftUI

@Observable
final class DecisionStore {
    private(set) var decisions: [Decision] = []

    /// The clock that review readiness is measured against. Stored, so views
    /// that depend on it redraw when `refreshReviewState()` moves it forward
    private(set) var today = Date()

    private let saveURL: URL
    private let queue = DispatchQueue(label: "DecisionStoreQueue", qos: .background)

    init(saveURL: URL = URL.documentsDirectory.appendingPathComponent("decisions.json")) {
        self.saveURL = saveURL

        load()
    }

    // MARK: - Public API

    func createDecision(
        title: String,
        category: DecisionCategory,
        stakes: DecisionStakes = .medium,
        expected: DecisionOutcome,
        notes: String? = nil,
        followUpDate: Date
    ) {
        let decision = Decision(
            title: title,
            category: category,
            stakes: stakes,
            expected: expected,
            notes: notes,
            followUpDate: followUpDate
        )

        add(decision)
        ReminderManager.shared.scheduleFollowUp(for: decision)
    }

    func add(_ decision: Decision) {
        decisions.insert(decision, at: 0)
        save()
    }

    func update(_ decision: Decision) {
        guard let index = decisions.firstIndex(where: { $0.id == decision.id }) else { return }
        let previous = decisions[index]
        decisions[index] = decision

        // A pending decision's reminder follows its review date
        if decision.actual == nil, decision.followUpDate != previous.followUpDate {
            ReminderManager.shared.cancelReminder(for: previous)
            ReminderManager.shared.scheduleFollowUp(for: decision)
        }

        save()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            ReminderManager.shared.cancelReminder(for: decisions[index])
        }
        decisions.remove(atOffsets: offsets)
        save()
    }

    func delete(_ decision: Decision) {
        // Use ID lookup for safety
        guard let index = decisions.firstIndex(where: { $0.id == decision.id }) else { return }
        
        // Cancel the notification before removing
        ReminderManager.shared.cancelReminder(for: decisions[index])
        
        decisions.remove(at: index)
        save()
    }

    func resolveDecision(
        id: UUID,
        actual: DecisionOutcome,
        reflection: String? = nil,
        secondaryFollowUpDate: Date? = nil
    ) {
        guard let index = decisions.firstIndex(where: { $0.id == id }) else { return }

        ReminderManager.shared.cancelReminder(for: decisions[index])

        decisions[index].actual = actual
        decisions[index].resolvedAt = Date()
        if let reflection, !reflection.isEmpty {
            decisions[index].reflection = reflection
        }
        if let secondaryFollowUpDate {
            decisions[index].secondaryFollowUpDate = secondaryFollowUpDate
            // Schedule secondary reminder
            ReminderManager.shared.scheduleSecondaryFollowUp(for: decisions[index])
        }

        save()
    }

    /// Records a re-rating of an already-marked decision. Passing a next date
    /// schedules another revisit; nil ends the chain.
    func addRevisit(
        id: UUID,
        outcome: DecisionOutcome,
        note: String? = nil,
        nextRevisitDate: Date? = nil
    ) {
        guard let index = decisions.firstIndex(where: { $0.id == id }),
              decisions[index].actual != nil else { return }

        ReminderManager.shared.cancelReminder(for: decisions[index])

        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        decisions[index].revisits.append(
            Revisit(outcome: outcome, note: trimmedNote?.isEmpty == false ? trimmedNote : nil)
        )
        decisions[index].secondaryFollowUpDate = nextRevisitDate

        if nextRevisitDate != nil {
            ReminderManager.shared.scheduleSecondaryFollowUp(for: decisions[index])
        }

        save()
    }

    /// Call after the Settings toggle changes. Turning reminders on re-creates
    /// every future reminder; turning them off removes all of them.
    func setRemindersEnabled(_ isEnabled: Bool) {
        if isEnabled {
            ReminderManager.shared.rescheduleAll(for: decisions)
        } else {
            ReminderManager.shared.cancelAllReminders()
        }
    }

    /// Review readiness depends on the clock, not just data. Call when the app
    /// returns to the foreground so "Ready to Review" reflects today.
    func refreshReviewState() {
        today = Date()
    }

    // Convenience helpers for views

    var pendingDecisions: [Decision] {
        decisions.filter { $0.actual == nil }
    }

    /// Reviews and revisits whose day has arrived, most overdue first
    var readyForReviewDecisions: [Decision] {
        decisions
            .filter { $0.isReadyForReview(asOf: today) }
            .sorted { ($0.nextReviewDate ?? .distantPast) < ($1.nextReviewDate ?? .distantPast) }
    }

    /// Pending decisions still waiting on their review day, soonest first
    var upcomingDecisions: [Decision] {
        decisions
            .filter { $0.actual == nil && !$0.isReadyForReview(asOf: today) }
            .sorted { $0.followUpDate < $1.followUpDate }
    }

    var completedDecisions: [Decision] {
        decisions.filter { $0.actual != nil }
    }

    /// Completed decisions not currently waiting on a revisit
    var historyDecisions: [Decision] {
        completedDecisions.filter { !$0.isReadyForReview(asOf: today) }
    }

    func decisions(in category: DecisionCategory?) -> [Decision] {
        guard let category else { return decisions }
        return decisions.filter { $0.category == category }
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else {
            decisions = []
            return
        }

        do {
            let data = try Data(contentsOf: saveURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode([Decision].self, from: data)
            decisions = decoded
        } catch {
            print("[DecisionStore] ❌ Failed to load decisions:", error)
            backUpUnreadableFile()
            decisions = []
        }
    }

    /// Copies an unreadable decisions.json aside before the next save overwrites it,
    /// so a decode failure (e.g. after a model change) never silently destroys data.
    private func backUpUnreadableFile() {
        let timestamp = Int(Date().timeIntervalSince1970)
        let backupURL = saveURL
            .deletingLastPathComponent()
            .appendingPathComponent("decisions-unreadable-\(timestamp).json")

        do {
            try FileManager.default.copyItem(at: saveURL, to: backupURL)
            print("[DecisionStore] Backed up unreadable file to", backupURL.lastPathComponent)
        } catch {
            print("[DecisionStore] ❌ Failed to back up unreadable file:", error)
        }
    }

    /// Blocks until queued writes finish. Tests use it before reading the file back
    func waitForPendingSaves() {
        queue.sync {}
    }

    private func save() {
        let currentDecisions = decisions

        queue.async { [saveURL] in
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(currentDecisions)
                try data.write(to: saveURL, options: [.atomic])
            } catch {
                print("[DecisionStore] ❌ Failed to save decisions:", error)
            }
        }
    }
}
