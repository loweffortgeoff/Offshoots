//
//  WidgetSummaryWriterTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
@Suite struct WidgetSummaryWriterTests {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("widget-summary-\(UUID().uuidString).json")
    let decisions = [Decision(title: "Take the job", category: .work, expected: .good,
                              createdAt: Make.day(0), followUpDate: Make.day(20))]

    private final class Counter: @unchecked Sendable { var count = 0 }

    private func read() -> WidgetSummary? {
        (try? Data(contentsOf: url)).flatMap(WidgetSummary.decode)
    }

    @Test func writesDecodableSummaryAndReloadsOnce() {
        let reloads = Counter()
        let writer = WidgetSummaryWriter(fileURL: url) { reloads.count += 1 }
        writer.update(decisions: decisions, blocked: false, now: Make.day(26))
        writer.waitForPendingWrites()
        #expect(read()?.items.map(\.title) == ["Take the job"])
        #expect(reloads.count == 1)
    }

    @Test func blockedWritesNothing() {
        let reloads = Counter()
        let writer = WidgetSummaryWriter(fileURL: url) { reloads.count += 1 }
        writer.update(decisions: decisions, blocked: true, now: Make.day(26))
        writer.waitForPendingWrites()
        #expect(!FileManager.default.fileExists(atPath: url.path))
        #expect(reloads.count == 0)
    }

    @Test func keepsOwnedFlagFromDiskUntilResolved() throws {
        try WidgetSummary(version: 1, hindsightOwned: true, items: []).encoded().write(to: url)
        let writer = WidgetSummaryWriter(fileURL: url) {}
        writer.update(decisions: decisions, blocked: false, now: Make.day(26))
        writer.waitForPendingWrites()
        #expect(read()?.hindsightOwned == true)
    }

    @Test func unchangedDataDoesNotReload() {
        let reloads = Counter()
        let writer = WidgetSummaryWriter(fileURL: url) { reloads.count += 1 }
        writer.update(decisions: decisions, blocked: false, now: Make.day(26))
        writer.update(decisions: decisions, blocked: false, now: Make.day(26))
        writer.waitForPendingWrites()
        #expect(reloads.count == 1)
    }

    @Test func ownershipChangeRewrites() {
        let reloads = Counter()
        let writer = WidgetSummaryWriter(fileURL: url) { reloads.count += 1 }
        writer.update(decisions: decisions, blocked: false, now: Make.day(26))
        writer.update(hindsightOwned: true)
        writer.update(hindsightOwned: false)
        writer.waitForPendingWrites()
        #expect(read()?.hindsightOwned == false)
        #expect(reloads.count == 3)
    }
}
