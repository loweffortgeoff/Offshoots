//
//  DecisionsExport.swift
//  Offshoots
//

import CoreTransferable
import UniformTypeIdentifiers

/// The decisions as a shareable JSON file, in the same format as decisions.json.
/// Encoding happens only when the share sheet asks for the file.
struct DecisionsExport: Transferable {
    let decisions: [Decision]

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { export in
            try DecisionStore.encode(export.decisions)
        }
        .suggestedFileName("Offshoots Decisions.json")
    }
}
