//
//  Fixture.swift
//  OffshootsTests
//
//  Created by Geoffrey Silva on 9/25/26.
//

import Foundation
import Testing
@testable import Offshoots

enum Fixture {
    /// Decodes `docs/fixtures/<name>.json` the same way `DecisionStore` does.
    /// The folder is synced into the test bundle, so this also works on a device
    static func load(_ name: String) throws -> [Decision] {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: name, withExtension: "json"))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Decision].self, from: Data(contentsOf: url))
    }

    private final class BundleToken {}
}
