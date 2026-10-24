import CoreTransferable
import UniformTypeIdentifiers
import Foundation

struct ReflectionBackupExport: Transferable {
    let decisions: [Decision]
    let readings: [SavedReflection]
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { try await ReflectionBackup.encode(decisions: $0.decisions, readings: $0.readings) }
            .suggestedFileName("Offshoots Full Backup.json")
    }
}
