//
//  StarterSuggestionTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
struct StarterSuggestionTests {

    private func logged(_ title: String) -> Decision {
        Decision(title: title, category: .other, expected: .good, followUpDate: Date())
    }

    @Test func sixExamplesOnePerCategory() {
        #expect(StarterSuggestion.all.count == 6)
        #expect(Set(StarterSuggestion.all.map(\.category)) == Set(DecisionCategory.allCases))
    }

    @Test func newUserSeesTheFirstThree() {
        #expect(StarterSuggestion.available(given: []) == Array(StarterSuggestion.all.prefix(3)))
    }

    @Test func aLoggedExampleDropsOut() {
        let first = StarterSuggestion.all[0]
        let shown = StarterSuggestion.available(given: [logged(first.title)])
        #expect(shown == Array(StarterSuggestion.all[1...3]))
    }

    @Test func otherTitlesDoNotHideExamples() {
        let shown = StarterSuggestion.available(given: [logged("Something else")])
        #expect(shown == Array(StarterSuggestion.all.prefix(3)))
    }

    @Test func noneAtTheCutoff() {
        let five = (1...StarterSuggestion.cutoff).map { logged("Decision \($0)") }
        #expect(StarterSuggestion.available(given: five).isEmpty)
    }
}
