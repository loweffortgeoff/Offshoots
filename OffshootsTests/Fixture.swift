//
//  Fixture.swift
//  OffshootsTests
//
//  Created by Geoffrey Silva on 9/25/26.
//

import Foundation
@testable import Offshoots

enum Fixture {
    /// Decodes `docs/fixtures/<name>.json` the same way `DecisionStore` does
    static func load(_ name: String) throws -> [Decision] {
        let url = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "docs/fixtures/\(name).json")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Decision].self, from: Data(contentsOf: url))
    }
}
