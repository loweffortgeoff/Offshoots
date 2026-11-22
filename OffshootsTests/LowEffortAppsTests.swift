//
//  LowEffortAppsTests.swift
//  OffshootsTests
//
//  Created by Geoffrey Silva on 11/22/26.
//

import Testing
import UIKit
@testable import Offshoots

/// Pins the Settings > We Also Make catalog: the other live apps, their App Store links and icons.
@MainActor
struct LowEffortAppsTests {

    @Test func theCatalogListsTheOtherLiveApps() {
        #expect(LowEffortApps.all.map(\.name) == ["Task(ed)", "EveryPaw", "AisleWise", "Weather in Words", "Tucked"])
    }

    @Test func eachAppHasAUniqueStoreID() {
        #expect(Set(LowEffortApps.all.map(\.id)).count == LowEffortApps.all.count)
    }

    @Test func eachAppOpensItsAppStorePage() {
        let urls = LowEffortApps.all.map { $0.appStoreURL?.absoluteString }
        #expect(urls == [
            "https://apps.apple.com/us/app/task-ed/id6755186421",
            "https://apps.apple.com/us/app/everypaw/id6754781167",
            "https://apps.apple.com/us/app/aislewise/id6755057084",
            "https://apps.apple.com/us/app/weather-in-words/id6806063498",
            "https://apps.apple.com/us/app/tucked-stuff-for-whenever/id6792490401",
        ])
    }

    @Test func eachAppIconIsInTheAssetCatalog() {
        for app in LowEffortApps.all {
            #expect(UIImage(named: app.iconName) != nil, "Missing icon: \(app.iconName)")
        }
    }
}
