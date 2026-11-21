//
//  AppRouteTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@Suite struct AppRouteTests {
    @Test(arguments: [AppRoute.log, .readyToReview, .hindsight, .decision(UUID())])
    func urlRoundTrip(_ route: AppRoute) {
        #expect(AppRoute(url: route.url) == route)
    }

    @Test func parsesExactURLs() {
        let id = UUID()
        #expect(AppRoute(url: URL(string: "offshoots://log")!) == .log)
        #expect(AppRoute(url: URL(string: "offshoots://revisits")!) == .readyToReview)
        #expect(AppRoute(url: URL(string: "offshoots://hindsight")!) == .hindsight)
        #expect(AppRoute(url: URL(string: "offshoots://decision/\(id.uuidString)")!) == .decision(id))
    }

    @Test func rejectsUnknownURLs() {
        for s in ["offshoots://nope", "offshoots://decision/not-a-uuid", "offshoots://decision", "https://log"] {
            #expect(AppRoute(url: URL(string: s)!) == nil)
        }
    }

    @Test @MainActor func missingDecisionOpensListRoot() {
        let kept = Make.decision()
        #expect(DecisionRoute.path(for: kept.id, in: [kept]).map(\.id) == [kept.id])
        #expect(DecisionRoute.path(for: UUID(), in: [kept]).isEmpty)
    }

    @Test func laterRouteCancelsAWaitingHindsightLink() {
        var pending = PendingHindsight()
        pending.note(.hindsight, target: .wait)
        #expect(pending.isWaiting)
        pending.note(.log, target: nil)
        #expect(!pending.isWaiting)
    }

    @Test func resolvedHindsightLinkStopsWaiting() {
        var pending = PendingHindsight()
        pending.note(.hindsight, target: .wait)
        pending.note(.hindsight, target: .purchase)
        #expect(!pending.isWaiting)
    }

    @Test func hindsightTarget() {
        #expect(HindsightRouteTarget.resolve(hasResolvedOwnership: false, canCapture: false, entryCount: 3) == .wait)
        #expect(HindsightRouteTarget.resolve(hasResolvedOwnership: true, canCapture: true, entryCount: 3) == .review)
        #expect(HindsightRouteTarget.resolve(hasResolvedOwnership: true, canCapture: true, entryCount: 0) == .insights)
        #expect(HindsightRouteTarget.resolve(hasResolvedOwnership: true, canCapture: false, entryCount: 3) == .purchase)
    }
}
