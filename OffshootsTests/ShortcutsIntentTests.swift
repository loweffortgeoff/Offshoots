//
//  ShortcutsIntentTests.swift
//  OffshootsTests
//
//  The service-backed intents are not run here: the hosted app registers the real
//  ShortcutsService, which would write to the simulator's journal. Their logic is
//  covered by ShortcutsServiceTests.
//

import AppIntents
import Foundation
import Testing
@testable import Offshoots

@Suite(.serialized) @MainActor struct ShortcutsIntentTests {
    private func pending(_ title: String = "Take the job", expected: DecisionOutcome = .neutral) -> Decision {
        Decision(title: title, category: .work, expected: expected, createdAt: Make.day(0), followUpDate: Make.day(30))
    }

    private func text(_ resource: LocalizedStringResource) -> String { String(localized: resource) }

    @Test func readyDialogsMatchSpecCopy() {
        #expect(text(ShortcutsDialog.ready([])) == "No decisions are ready to review right now.")
        #expect(text(ShortcutsDialog.ready([pending()])) == "1 decision is ready to review: Take the job.")
        #expect(text(ShortcutsDialog.ready([pending(), pending("Sell the car"), pending("Move")]))
                == "3 decisions are ready to review, starting with Take the job.")
    }

    @Test func outcomeDialogsMatchSpecCopy() {
        var resolved = pending()
        resolved.actual = .good
        #expect(text(ShortcutsDialog.firstOutcome(resolved)) == "Recorded Good for \"Take the job\" (you expected Neutral).")
        #expect(text(ShortcutsDialog.revisit(resolved, outcome: .veryGood)) == "Added revisit: Great for \"Take the job\".")
    }

    @Test func loggedDialogMatchesSpecCopy() {
        let date = Make.day(30).formatted(Date.FormatStyle(date: .abbreviated, time: .omitted))
        #expect(text(ShortcutsDialog.logged(pending())) == "Logged \"Take the job\" in Work. Review set for \(date).")
    }

    @Test func intentsRequireAuthentication() {
        #expect(LogDecisionIntent.authenticationPolicy == .requiresAuthentication)
        #expect(RecordOutcomeIntent.authenticationPolicy == .requiresAuthentication)
        #expect(ShowRevisitsDueIntent.authenticationPolicy == .requiresAuthentication)
        #expect(OpenDecisionIntent.authenticationPolicy == .requiresAuthentication)
        #expect(OpenReadyToReviewIntent.authenticationPolicy == .requiresAuthentication)
    }

    @Test func openIntentsOpenTheApp() {
        #expect(OpenDecisionIntent.openAppWhenRun)
        #expect(OpenReadyToReviewIntent.openAppWhenRun)
        #expect(OpenReadyToReviewIntent.isDiscoverable)
    }

    @Test func openDecisionRoutesToDecision() async throws {
        var received: AppRoute?
        AppRouteDispatcher.shared.register { received = $0 }
        defer { AppRouteDispatcher.shared.register { NotificationDelegate.shared.pendingRoute = $0 } }

        let decision = pending()
        let intent = OpenDecisionIntent()
        intent.target = DecisionEntity(decision, now: Make.day(26))
        _ = try await intent.perform()
        #expect(received == .decision(decision.id))
    }

    @Test func openReadyToReviewRoutes() async throws {
        var received: AppRoute?
        AppRouteDispatcher.shared.register { received = $0 }
        defer { AppRouteDispatcher.shared.register { NotificationDelegate.shared.pendingRoute = $0 } }

        _ = try await OpenReadyToReviewIntent().perform()
        #expect(received == .readyToReview)
    }

    @Test func appShortcutsHaveThreeEntries() {
        #expect(OffshootsShortcuts.appShortcuts.count == 3)
    }
}
