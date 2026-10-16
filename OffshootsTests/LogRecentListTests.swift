//
//  LogRecentListTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
struct LogRecentListTests {

    // Review Focus 3
    @Test func noDecisionsIsNone() {
        #expect(LogRecentList.make(category: .work, from: []) == .none)
    }

    @Test func pickedCategoryComesFirst() {
        let money1 = Make.decision(title: "M1", category: .money)
        let work1 = Make.decision(title: "W1", category: .work)
        let work2 = Make.decision(title: "W2", category: .work)
        #expect(LogRecentList.make(category: .work, from: [money1, work1, work2]) == .category(.work, [work1, work2]))
    }

    // Review Focus 3
    @Test func emptyCategoryFallsBackToAll() {
        let money1 = Make.decision(title: "M1", category: .money)
        let work1 = Make.decision(title: "W1", category: .work)
        #expect(LogRecentList.make(category: .health, from: [money1, work1]) == .all([money1, work1]))
    }

    @Test func listStopsAtTen() {
        let all = (1...12).map { Make.decision(title: "W\($0)", category: .work) }
        #expect(LogRecentList.make(category: .work, from: all) == .category(.work, Array(all.prefix(10))))
    }

    @Test func keepsStoreOrder() {
        let work1 = Make.decision(title: "W1", category: .work)
        let work2 = Make.decision(title: "W2", category: .work)
        #expect(LogRecentList.make(category: .work, from: [work2, work1]) == .category(.work, [work2, work1]))
    }
}
