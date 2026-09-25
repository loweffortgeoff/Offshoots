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
struct DecisionStoreTests {

    /// A fresh folder per test, so tests never touch the app's real decisions.json
    let folder: URL
    var saveURL: URL { folder.appending(path: "decisions.json") }

    init() throws {
        folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
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

    @Test func unreadableFileIsBackedUpNotLost() throws {
        try Data("not json".utf8).write(to: saveURL)

        let store = DecisionStore(saveURL: saveURL)

        #expect(store.decisions.isEmpty)
        let files = try FileManager.default.contentsOfDirectory(atPath: folder.path())
        #expect(files.contains { $0.hasPrefix("decisions-unreadable-") })
    }
}
