//
//  PredictionResultBannerTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
struct PredictionResultBannerTests {

    @Test func messages() {
        #expect(PredictionResultBanner.message(for: 0) == "You predicted correctly!")
        #expect(PredictionResultBanner.message(for: 1) == "Close. It went a little better than you expected.")
        #expect(PredictionResultBanner.message(for: -1) == "Close. It went a little worse than you expected.")
        #expect(PredictionResultBanner.message(for: 2) == "It went better than you expected.")
        #expect(PredictionResultBanner.message(for: -4) == "It went worse than you expected.")
    }

    @Test func unlockText() {
        #expect(PredictionResultBanner.unlockText(markedCount: 1) == "1 of 3 marked · Optimism unlocks at 3")
        #expect(PredictionResultBanner.unlockText(markedCount: 2) == "2 of 3 marked · Optimism unlocks at 3")
        #expect(PredictionResultBanner.unlockText(markedCount: 3) == "3 of 6 marked · Trend unlocks at 6")
        #expect(PredictionResultBanner.unlockText(markedCount: 5) == "5 of 6 marked · Trend unlocks at 6")
        #expect(PredictionResultBanner.unlockText(markedCount: 6) == nil)
    }
}
