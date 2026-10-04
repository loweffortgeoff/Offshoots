//
//  DecisionsImport.swift
//  Offshoots
//

import Foundation

/// Reads a file made by Export Decisions. The format is decisions.json, so an export restores as is.
enum DecisionsImport {
    enum ImportError: Error, Equatable {
        case notAnExport
        case unreadable

        var message: String {
            switch self {
            case .notAnExport: "This file is not an Offshoots export."
            case .unreadable: "The file could not be opened. Try again."
            }
        }
    }

    static func read(from url: URL) throws -> [Decision] {
        // Files picked outside the app's container need scoped access
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ImportError.unreadable
        }
        do {
            return try DecisionStore.decode(data)
        } catch {
            throw ImportError.notAnExport
        }
    }
}
