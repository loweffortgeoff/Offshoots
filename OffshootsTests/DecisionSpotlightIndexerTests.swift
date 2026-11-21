//
//  DecisionSpotlightIndexerTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
final class DecisionSpotlightIndexerTests {
    enum Call: Equatable {
        case index([UUID])
        case delete([UUID])
        case deleteAll
    }

    final class FakeIndex: DecisionSearchIndexing {
        var calls: [Call] = []
        func index(_ entities: [DecisionEntity]) async throws { calls.append(.index(entities.map(\.id))) }
        func delete(ids: [UUID]) async throws { calls.append(.delete(ids)) }
        func deleteAll() async throws { calls.append(.deleteAll) }
    }

    let folder: URL
    let store: DecisionStore
    let fake = FakeIndex()
    let indexer: DecisionSpotlightIndexer
    var changes: [DecisionStoreChange] = []

    let a = Decision(title: "Take the job", category: .work, expected: .good,
                     createdAt: Make.day(0), followUpDate: Make.day(20))
    let b = Decision(title: "Sell the car", category: .money, expected: .bad,
                     createdAt: Make.day(1), followUpDate: Make.day(21))

    init() throws {
        folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        store = DecisionStore(saveURL: folder.appending(path: "decisions.json"))
        indexer = DecisionSpotlightIndexer(index: fake, now: { Make.day(26) })
    }

    deinit {
        try? FileManager.default.removeItem(at: folder)
    }

    private func record() {
        store.onChange = { [unowned self] in changes.append($0) }
    }

    @Test func storeReportsEachMutation() {
        record()
        store.add(a)
        var renamed = a
        renamed.title = "Take the new job"
        store.update(renamed)
        store.delete(renamed)
        store.add(b)
        store.delete(at: IndexSet(integer: 0))
        store.replaceAll(with: [b])
        store.deleteAll()
        #expect(changes == [.upserted([a.id]), .upserted([a.id]), .deleted([a.id]),
                            .upserted([b.id]), .deleted([b.id]), .replacedAll, .replacedAll])
    }

    @Test func resolveAndRevisitReindex() {
        store.add(a)
        record()
        store.resolveDecision(id: a.id, actual: .good)
        store.addRevisit(id: a.id, outcome: .bad)
        store.resolveDecision(id: a.id, actual: .bad)        // already resolved: no write, no change
        store.addRevisit(id: UUID(), outcome: .bad)          // missing: no write, no change
        #expect(changes == [.upserted([a.id]), .upserted([a.id])])
    }

    @Test func blockedStoreSkipsIndexing() async {
        record()
        store.blockAfterRestoreFailure()
        store.add(a)
        #expect(changes.isEmpty)

        indexer.syncAll(decisions: [a], blocked: true)
        await indexer.drain()
        #expect(fake.calls.isEmpty)
    }

    @Test func handlesEachChangeKind() async {
        indexer.handle(.upserted([a.id]), decisions: [a, b])
        indexer.handle(.deleted([b.id]), decisions: [a])
        indexer.handle(.replacedAll, decisions: [b])
        indexer.handle(.replacedAll, decisions: [])
        await indexer.drain()
        #expect(fake.calls == [.index([a.id]), .delete([b.id]), .deleteAll, .index([b.id]), .deleteAll])
    }

    @Test func syncAllIndexesEverything() async {
        indexer.syncAll(decisions: [a, b], blocked: false)
        await indexer.drain()
        #expect(fake.calls == [.index([a.id, b.id])])
    }
}
