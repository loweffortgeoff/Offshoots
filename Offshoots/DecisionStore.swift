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
import Combine
internal import SwiftUI

final class DecisionStore: ObservableObject {
    @Published private(set) var decisions: [Decision] = []

    private let saveURL: URL
    private let queue = DispatchQueue(label: "DecisionStoreQueue", qos: .background)

    init() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        self.saveURL = documentsDirectory.appendingPathComponent("decisions.json")

        load()
    }

    // MARK: - Public API

    func createDecision(
        title: String,
        category: DecisionCategory,
        expected: DecisionOutcome,
        notes: String? = nil,
        followUpDate: Date
    ) {
        let decision = Decision(
            title: title,
            category: category,
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
        decisions[index] = decision
        save()
    }

    func delete(at offsets: IndexSet) {
        // Note: This method deletes directly from the main array based on index.
        // Be careful not to use this with filtered lists (like pending/completed).
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
        reflection: String? = nil
    ) {
        guard let index = decisions.firstIndex(where: { $0.id == id }) else { return }

        ReminderManager.shared.cancelReminder(for: decisions[index])

        decisions[index].actual = actual
        if let reflection, !reflection.isEmpty {
            decisions[index].reflection = reflection
        }

        save()
    }

    // Convenience helpers for views

    var pendingDecisions: [Decision] {
        decisions.filter { $0.actual == nil }
    }

    var completedDecisions: [Decision] {
        decisions.filter { $0.actual != nil }
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
            decisions = []
        }
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
