//
//  ShortcutsServiceTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
final class ShortcutsServiceTests {
    private final class Counter: @unchecked Sendable { var count = 0 }

    /// A fresh folder per test, so tests never touch the app's real files
    let folder: URL
    let store: DecisionStore
    let writer: WidgetSummaryWriter
    let service: ShortcutsService
    private let reloads = Counter()
    let now = Make.day(26)

    init() throws {
        folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        store = DecisionStore(saveURL: folder.appending(path: "decisions.json"))
        let reloads = reloads
        writer = WidgetSummaryWriter(fileURL: folder.appending(path: "widget-summary.json")) { reloads.count += 1 }
        let now = now
        service = ShortcutsService(store: store, widgetSummary: writer, now: { now })
    }

    deinit {
        try? FileManager.default.removeItem(at: folder)
    }

    private func reloadCount() -> Int {
        writer.waitForPendingWrites()
        return reloads.count
    }

    @discardableResult
    private func log(_ title: String = "Take the job", reviewDate: Date? = nil, notes: String? = nil) throws -> Decision {
        try service.logDecision(title: title, expected: .good, category: .other,
                                stakes: .medium, reviewDate: reviewDate, notes: notes)
    }

    private func seedPending(_ title: String = "Take the job", category: DecisionCategory = .work,
                             expected: DecisionOutcome = .neutral, due: Date = Make.day(20)) -> Decision {
        let decision = Decision(title: title, category: category, expected: expected,
                                createdAt: Make.day(0), followUpDate: due)
        store.add(decision)
        return decision
    }

    // MARK: - Log a Decision

    @Test func logsWithDefaults() throws {
        let decision = try log()
        #expect(store.decisions.map(\.id) == [decision.id])
        #expect(decision.followUpDate == ReviewDatePreset.tomorrow.date(from: now))
        #expect(decision.category == .other)
        #expect(decision.stakes == .medium)
        #expect(decision.expected == .good)
        #expect(decision.notes == nil)
        #expect(reloadCount() == 1)
    }

    @Test func logsExplicitValues() throws {
        let decision = try service.logDecision(title: "Move", expected: .veryBad, category: .home,
                                               stakes: .high, reviewDate: Make.day(30), notes: "Lease ends")
        #expect(decision.category == .home)
        #expect(decision.stakes == .high)
        #expect(decision.expected == .veryBad)
        #expect(decision.followUpDate == Make.day(30))
        #expect(decision.notes == "Lease ends")
    }

    @Test func trimsTitleAndRefusesBlank() throws {
        #expect(throws: ShortcutsError.blankTitle) { try self.log("  \n") }
        #expect(store.decisions.isEmpty)
        #expect(reloadCount() == 0)

        let decision = try log("  Take the job ", notes: "   ")
        #expect(decision.title == "Take the job")
        #expect(decision.notes == nil)
    }

    @Test func reviewDateMustBeTomorrowOrLater() throws {
        #expect(throws: ShortcutsError.reviewDateTooEarly) { try self.log(reviewDate: self.now) }
        #expect(store.decisions.isEmpty)
        try log(reviewDate: Make.day(27))
        #expect(store.decisions.count == 1)
    }

    @Test func blockedStoreRefusesEveryWrite() throws {
        let pending = seedPending()
        store.blockAfterRestoreFailure()
        #expect(service.isBlocked)
        #expect(throws: ShortcutsError.blocked) { try self.log() }
        #expect(throws: ShortcutsError.blocked) {
            try self.service.recordOutcome(decisionID: pending.id, outcome: .good, note: nil, nextRevisitDate: nil)
        }
        #expect(store.decisions.map(\.id) == [pending.id])
        #expect(store.decisions.first?.actual == nil)
        #expect(reloadCount() == 0)
    }

    // MARK: - Record Outcome

    @Test func firstOutcomeThenRevisit() throws {
        let pending = seedPending()

        guard case .firstOutcome(let first) = try service.recordOutcome(
            decisionID: pending.id, outcome: .good, note: nil, nextRevisitDate: nil) else {
            Issue.record("Expected a first outcome"); return
        }
        #expect(first.actual == .good)
        #expect(first.hindsight == nil)
        #expect(first.revisits.isEmpty)

        guard case .revisit(let second) = try service.recordOutcome(
            decisionID: pending.id, outcome: .bad, note: "  ", nextRevisitDate: Make.day(30)) else {
            Issue.record("Expected a revisit"); return
        }
        // The writer skips unchanged summaries; a new revisit date changes it
        #expect(second.secondaryFollowUpDate == Make.day(30))
        #expect(second.actual == .good)
        #expect(second.revisits.map(\.outcome) == [.bad])
        #expect(second.revisits.last?.note == nil)
        #expect(second.revisits.last?.hindsight == nil)
        #expect(store.decisions.first == second)
        #expect(reloadCount() == 2)
    }

    @Test func firstOutcomeKeepsNoteAndNextDate() throws {
        let pending = seedPending()
        let result = try service.recordOutcome(decisionID: pending.id, outcome: .veryGood,
                                               note: "Worth it", nextRevisitDate: Make.day(40))
        guard case .firstOutcome(let decision) = result else { Issue.record("Expected a first outcome"); return }
        #expect(decision.reflection == "Worth it")
        #expect(decision.secondaryFollowUpDate == Make.day(40))
    }

    @Test func missingDecisionThrowsAndWritesNothing() {
        #expect(throws: ShortcutsError.decisionMissing) {
            try self.service.recordOutcome(decisionID: UUID(), outcome: .good, note: nil, nextRevisitDate: nil)
        }
        #expect(reloadCount() == 0)
    }

    @Test func revisitDateTodayIsAllowed() throws {
        let pending = seedPending()
        #expect(throws: ShortcutsError.revisitDateInPast) {
            try self.service.recordOutcome(decisionID: pending.id, outcome: .good, note: nil, nextRevisitDate: Make.day(25))
        }
        #expect(store.decisions.first?.actual == nil)
        _ = try service.recordOutcome(decisionID: pending.id, outcome: .good, note: nil, nextRevisitDate: now)
        #expect(store.decisions.first?.secondaryFollowUpDate == now)
    }

    // MARK: - Ready to Review

    @Test func readyForReviewFiltersByCategoryAndDueDay() {
        _ = seedPending("work due today", category: .work, due: now)
        _ = seedPending("money overdue", category: .money, due: Make.day(24))
        _ = seedPending("work due tomorrow", category: .work, due: Make.day(27))
        store.add(Decision(title: "work marked", category: .work, expected: .good, actual: .good,
                           createdAt: Make.day(0), followUpDate: Make.day(10)))

        #expect(service.readyForReview(category: nil).map(\.title) == ["money overdue", "work due today"])
        #expect(service.readyForReview(category: .work).map(\.title) == ["work due today"])
        #expect(service.readyForReview(category: .health).isEmpty)
    }

    // MARK: - Errors

    @Test func errorMessagesMatchSpecCopy() {
        let expected: [ShortcutsError: String] = [
            .blocked: "Offshoots needs attention before it can save. Open the app to finish the restore.",
            .blankTitle: "What decision are you making?",
            .reviewDateTooEarly: "Pick a review date of tomorrow or later.",
            .revisitDateInPast: "Pick a revisit date of today or later.",
            .decisionMissing: "That decision is no longer in Offshoots.",
        ]
        for (error, message) in expected {
            #expect(String(localized: error.localizedStringResource) == message)
        }
    }
}
