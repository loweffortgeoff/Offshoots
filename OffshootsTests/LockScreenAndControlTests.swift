//
//  LockScreenAndControlTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@Suite @MainActor struct LockScreenAndControlTests {
    @Test func dispatcherDeliversImmediatelyAfterRegistration() {
        let dispatcher = AppRouteDispatcher()
        var received: [AppRoute] = []
        dispatcher.register { received.append($0) }

        dispatcher.send(.log)
        dispatcher.send(.readyToReview)

        #expect(received == [.log, .readyToReview])
    }

    @Test func dispatcherQueuesColdLaunchRouteUntilRegistered() {
        let dispatcher = AppRouteDispatcher()
        dispatcher.send(.log)

        var received: [AppRoute] = []
        dispatcher.register { received.append($0) }

        #expect(received == [.log])
    }

    @Test func dispatcherReplacesUnconsumedQueuedRoute() {
        let dispatcher = AppRouteDispatcher()
        dispatcher.send(.readyToReview)
        dispatcher.send(.log)

        var received: [AppRoute] = []
        dispatcher.register { received.append($0) }

        #expect(received == [.log])
    }

    @Test func openLogIntentStaysHiddenFromShortcuts() {
        #expect(OpenLogDecisionIntent.openAppWhenRun == true)
        #expect(OpenLogDecisionIntent.isDiscoverable == false)
    }

    @Test func openLogIntentRoutesToLog() async throws {
        var received: AppRoute?
        AppRouteDispatcher.shared.register { received = $0 }
        defer {
            AppRouteDispatcher.shared.register { NotificationDelegate.shared.pendingRoute = $0 }
        }

        _ = try await OpenLogDecisionIntent().perform()
        #expect(received == .log)
    }

    @Test func rectangularRouteOpensSingleDueDecisionElseReadyToReview() {
        let first = WidgetSummary.Item(id: UUID(), title: "First", dueDate: Make.day(25))
        let second = WidgetSummary.Item(id: UUID(), title: "Second", dueDate: Make.day(26))

        #expect(LockScreenPresentation.rectangularRoute(due: []) == .readyToReview)
        #expect(LockScreenPresentation.rectangularRoute(due: [first]) == .decision(first.id))
        #expect(LockScreenPresentation.rectangularRoute(due: [first, second]) == .readyToReview)
    }

    @Test func inlineLabelCoversDueUpcomingAndEmpty() {
        let now = Make.day(26)

        let oneDue = LockScreenPresentation.inlineLabel(dueCount: 1, nextDueDate: nil, now: now)
        #expect(oneDue == LockScreenInlineLabel(text: "1 ready to review", systemImage: "bell.badge.fill"))

        let manyDue = LockScreenPresentation.inlineLabel(dueCount: 3, nextDueDate: Make.day(28), now: now)
        #expect(manyDue == LockScreenInlineLabel(text: "3 ready to review", systemImage: "bell.badge.fill"))

        let upcomingSoon = LockScreenPresentation.inlineLabel(dueCount: 0, nextDueDate: Make.day(28), now: now)
        #expect(upcomingSoon.systemImage == "bell")
        #expect(upcomingSoon.text.hasPrefix("Next review "))

        let upcomingFar = LockScreenPresentation.inlineLabel(dueCount: 0, nextDueDate: Make.day(40), now: now)
        #expect(upcomingFar.systemImage == "bell")
        #expect(upcomingFar.text.hasPrefix("Next review "))

        let empty = LockScreenPresentation.inlineLabel(dueCount: 0, nextDueDate: nil, now: now)
        #expect(empty == LockScreenInlineLabel(text: "Nothing to review", systemImage: "checkmark"))
    }

    @Test func rectangularEmptySubtitleOmitsTitlesAndFormatsDate() {
        let now = Make.day(26)
        #expect(LockScreenPresentation.rectangularEmptySubtitle(nextDueDate: nil, now: now) == "Log a decision")
        #expect(LockScreenPresentation.rectangularEmptySubtitle(nextDueDate: Make.day(28), now: now).hasPrefix("Next: "))
        #expect(LockScreenPresentation.rectangularEmptySubtitle(nextDueDate: Make.day(40), now: now).hasPrefix("Next: "))
    }
}
