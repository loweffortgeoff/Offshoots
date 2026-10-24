import CoreTransferable
import UniformTypeIdentifiers
import Foundation

struct ReflectionRecoveryExport: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { try Data(contentsOf: $0.url) }
            .suggestedFileName("Offshoots Reflection Recovery.json")
    }
}
