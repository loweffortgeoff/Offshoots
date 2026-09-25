//
//  DecisionStoreTests.swift
//  OffshootsTests
//
//  Created by Geoffrey Silva on 9/25/26.
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
final class DecisionStoreTests {

    /// A fresh folder per test, so tests never touch the app's real decisions.json
    let folder: URL
    var saveURL: URL { folder.appending(path: "decisions.json") }

    init() throws {
        folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: folder)
    }

    @Test func savedDecisionsLoadBack() throws {
        let decisions = try Fixture.load("insights-seed")
        let store = DecisionStore(saveURL: saveURL)
        for decision in decisions.reversed() {
            store.add(decision)
        }
        store.waitForPendingSaves()

        let reloaded = DecisionStore(saveURL: saveURL)
        #expect(reloaded.decisions == decisions)
    }

    @Test func readinessFollowsTheGivenDay() {
        let calendar = Calendar.current
        let now = AnalyticsEngineTests.now
        let laterToday = calendar.date(byAdding: .hour, value: 6, to: calendar.startOfDay(for: now))!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let decision = Decision(title: "Due", category: .work, expected: .good, followUpDate: laterToday)

        // Day-granular: due any time on its review day, not before
        #expect(decision.isReadyForReview(asOf: now))
        #expect(!decision.isReadyForReview(asOf: calendar.date(byAdding: .day, value: -1, to: now)!))
        #expect(!Decision(title: "Later", category: .work, expected: .good, followUpDate: tomorrow)
            .isReadyForReview(asOf: now))
    }

    @Test func refreshMovesDecisionsIntoReadyToReview() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let decision = Decision(title: "Tomorrow", category: .work, expected: .good, followUpDate: tomorrow)
        let store = DecisionStore(saveURL: saveURL)
        store.add(decision)

        #expect(store.readyForReviewDecisions.isEmpty)
        #expect(store.upcomingDecisions == [decision])

        store.refreshReviewState(now: tomorrow)

        #expect(store.readyForReviewDecisions == [decision])
        #expect(store.upcomingDecisions.isEmpty)
    }

    @Test func exportMatchesTheSavedFile() throws {
        let decisions = try Fixture.load("insights-seed")
        let store = DecisionStore(saveURL: saveURL)
        for decision in decisions.reversed() {
            store.add(decision)
        }
        store.waitForPendingSaves()

        let exported = try DecisionStore.encode(store.decisions)

        // The export is the same file the store reads, so it can be restored
        #expect(exported == (try Data(contentsOf: saveURL)))
        #expect(try DecisionStore.decode(exported) == decisions)
    }

    @Test func deleteAllEmptiesTheStoreAndTheFile() throws {
        let store = DecisionStore(saveURL: saveURL)
        for decision in try Fixture.load("insights-seed") {
            store.add(decision)
        }

        store.deleteAll()
        store.waitForPendingSaves()

        #expect(store.decisions.isEmpty)
        #expect(DecisionStore(saveURL: saveURL).decisions.isEmpty)
    }

    @Test func unreadableFileIsBackedUpNotLost() throws {
        try Data("not json".utf8).write(to: saveURL)

        let store = DecisionStore(saveURL: saveURL)

        #expect(store.decisions.isEmpty)
        let files = try FileManager.default.contentsOfDirectory(atPath: folder.path())
        #expect(files.contains { $0.hasPrefix("decisions-unreadable-") })
    }
}
