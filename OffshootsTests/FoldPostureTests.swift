//
//  FoldPostureTests.swift
//  OffshootsTests
//

import Foundation
import SwiftUI
import Testing
@testable import Offshoots

/// Region numbers come from the 2026-10-07 iPhone Duo probe (see the fold layout spec).
@MainActor
struct FoldPostureTests {

    /// Partly open, portrait: 669 x 951 screen
    static let horizontalBand = FoldRegion(
        frame: CGRect(x: 0, y: 455, width: 669, height: 40),
        margins: EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
    )

    /// Partly open, landscape: 951 x 669 screen
    static let verticalBand = FoldRegion(
        frame: CGRect(x: 455, y: 0, width: 40, height: 669),
        margins: EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
    )

    @Test func noRegionsIsFlat() {
        #expect(FoldPosture(regions: []) == .flat)
    }

    @Test func horizontalBandKeepsOutTheBandAndItsMargins() {
        let posture = FoldPosture(regions: [Self.horizontalBand])
        #expect(posture == .folded(bandAxis: .horizontal, keepOut: CGRect(x: 0, y: 435, width: 669, height: 80)))
    }

    @Test func verticalBandKeepsOutTheBandAndItsMargins() {
        let posture = FoldPosture(regions: [Self.verticalBand])
        #expect(posture == .folded(bandAxis: .vertical, keepOut: CGRect(x: 435, y: 0, width: 80, height: 669)))
    }

    @Test func horizontalBandFitsTheTopPane() {
        let posture = FoldPosture(regions: [Self.horizontalBand])
        #expect(posture.paneFit(containerWidth: 669, ownsWideLayout: false) == .top(height: 435))
    }

    @Test func verticalBandFitsTheLeadingPane() {
        let posture = FoldPosture(regions: [Self.verticalBand])
        #expect(posture.paneFit(containerWidth: 951, ownsWideLayout: false) == .leading(width: 435))
    }

    @Test func flatFitsACentredReadableColumn() {
        #expect(FoldPosture.flat.paneFit(containerWidth: 951, ownsWideLayout: false) == .centered(maxWidth: 600))
        #expect(FoldPosture.flat.paneFit(containerWidth: 440, ownsWideLayout: false) == .centered(maxWidth: 600))
    }

    @Test func wideLayoutOwnerFillsTheScreenInWideLandscape() {
        let folded = FoldPosture(regions: [Self.verticalBand])
        #expect(folded.paneFit(containerWidth: 951, ownsWideLayout: true) == .fill)
        #expect(FoldPosture.flat.paneFit(containerWidth: 951, ownsWideLayout: true) == .fill)
    }

    @Test func wideLayoutOwnerStillFitsThePaneInPortraitAndOnPhones() {
        let folded = FoldPosture(regions: [Self.horizontalBand])
        #expect(folded.paneFit(containerWidth: 669, ownsWideLayout: true) == .top(height: 435))
        #expect(FoldPosture.flat.paneFit(containerWidth: 440, ownsWideLayout: true) == .centered(maxWidth: 600))
    }

    // Review Focus 1: more than one region
    @Test func usesTheFirstRegionWhenThereAreSeveral() {
        let posture = FoldPosture(regions: [Self.verticalBand, Self.horizontalBand])
        #expect(posture == FoldPosture(regions: [Self.verticalBand]))
    }

    // Review Focus 2: a square region
    @Test func squareRegionCountsAsHorizontal() {
        let square = FoldRegion(frame: CGRect(x: 10, y: 100, width: 40, height: 40), margins: EdgeInsets())
        #expect(FoldPosture(regions: [square]) == .folded(bandAxis: .horizontal, keepOut: CGRect(x: 10, y: 100, width: 40, height: 40)))
    }

    @Test func twoPanesNeedAWideScreen() {
        #expect(FoldLayout.usesTwoPanes(width: 951))
        #expect(FoldLayout.usesTwoPanes(width: 900))
        #expect(!FoldLayout.usesTwoPanes(width: 899))
        #expect(!FoldLayout.usesTwoPanes(width: 440))
    }
}
