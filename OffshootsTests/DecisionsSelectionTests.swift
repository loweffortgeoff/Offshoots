//
//  DecisionsSelectionTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
struct DecisionsSelectionTests {

    @Test func emptyPathSelectsNothing() throws {
        let decisions = try Fixture.load("insights-seed")
        #expect(DecisionsSelection.current(path: [], in: decisions) == nil)
    }

    @Test func lastDecisionInThePathIsSelected() throws {
        let decisions = try Fixture.load("insights-seed")
        let path = [decisions[0], decisions[1]]
        #expect(DecisionsSelection.current(path: path, in: decisions) == decisions[1])
    }

    // Review Focus 3: the selected decision was deleted
    @Test func deletedDecisionSelectsNothing() throws {
        let decisions = try Fixture.load("insights-seed")
        let remaining = Array(decisions.dropFirst())
        #expect(DecisionsSelection.current(path: [decisions[0]], in: remaining) == nil)
    }
}
