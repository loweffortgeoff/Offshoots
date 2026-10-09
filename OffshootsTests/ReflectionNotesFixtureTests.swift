//
//  ReflectionNotesFixtureTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

/// Pins the shape of `reflection-notes.json`, so a fixture edit that changes the groups
/// the Reflection prompts read is caught here first.
@MainActor
struct ReflectionNotesFixtureTests {

    private func marked() throws -> [Decision] {
        try Fixture.load("reflection-notes").filter { $0.actual != nil }
    }

    @Test func counts() throws {
        let decisions = try Fixture.load("reflection-notes")
        #expect(decisions.count == 18)
        #expect(AnalyticsEngine.markedCount(from: decisions) == 17)
    }

    @Test func groupsByResultAgainstThePrediction() throws {
        let gaps = try marked().compactMap(AnalyticsEngine.predictionGap)
        #expect(gaps.filter { $0 < 0 }.count == 6)
        #expect(gaps.filter { $0 == 0 }.count == 4)
        #expect(gaps.filter { $0 > 0 }.count == 7)
    }

    @Test func moneyHasEnoughHistoryForLookBack() throws {
        #expect(try marked().filter { $0.category == .money }.count == 5)
    }

    @Test func everyMarkedDecisionHasALogNote() throws {
        #expect(try marked().allSatisfy { $0.notes?.isEmpty == false })
    }
}
