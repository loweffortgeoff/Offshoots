//
//  DashboardSelectionTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
struct DashboardSelectionTests {

    @Test func noDecisionsSelectsNothing() {
        #expect(DashboardSelection.current(selectedID: nil, ready: [], all: []) == nil)
    }

    @Test func defaultIsTheFirstReadyDecision() {
        let a = Make.decision(title: "A"), b = Make.decision(title: "B")
        #expect(DashboardSelection.current(selectedID: nil, ready: [b], all: [a, b]) == b)
    }

    @Test func defaultIsTheMostRecentWhenNothingIsReady() {
        let a = Make.decision(title: "A"), b = Make.decision(title: "B")
        #expect(DashboardSelection.current(selectedID: nil, ready: [], all: [a, b]) == a)
    }

    // Review Focus 1: marking an outcome moves the decision out of Ready to Review
    @Test func selectionStaysWhenItLeavesReadyToReview() {
        let a = Make.decision(title: "A"), b = Make.decision(title: "B")
        #expect(DashboardSelection.current(selectedID: a.id, ready: [b], all: [a, b]) == a)
    }

    // Review Focus 2: the selected decision was deleted
    @Test func deletedSelectionFallsBackToDefault() {
        let a = Make.decision(title: "A"), b = Make.decision(title: "B")
        #expect(DashboardSelection.current(selectedID: a.id, ready: [b], all: [b]) == b)
    }

    // Review Focus 1, the default case: DashboardView pins the shown decision's ID,
    // so marking the default decision's outcome keeps it on screen
    @Test func pinnedDefaultStaysAfterItsOutcomeIsMarked() {
        let a = Make.decision(title: "A"), b = Make.decision(title: "B")
        let shown = DashboardSelection.current(selectedID: nil, ready: [a], all: [b, a])
        #expect(shown == a)
        #expect(DashboardSelection.current(selectedID: shown?.id, ready: [], all: [b, a]) == a)
    }
}
