internal import SwiftUI
import UniformTypeIdentifiers

struct SettingsDataSection: View {
    @Environment(DecisionStore.self) private var store
    @Environment(ReflectionHistoryStore.self) private var history
    @State private var showDeleteAllConfirmation = false
    @State private var showImporter = false
    @State private var importFullBackup = false
    @State private var pendingImport: [Decision]?
    @State private var pendingBackup: ReflectionBackup?
    @State private var importError: String?

    var body: some View {
        Section {
            ShareLink(item: DecisionsExport(decisions: store.decisions), preview: SharePreview("Offshoots Decisions")) {
                Label("Export Decisions", systemImage: "square.and.arrow.up")
            }
            .disabled(store.decisions.isEmpty)
            Button { importFullBackup = false; showImporter = true } label: {
                Label("Import Decisions", systemImage: "square.and.arrow.down")
            }
            if history.loadError == nil {
                ShareLink(item: ReflectionBackupExport(decisions: store.decisions, readings: history.readings), preview: SharePreview("Offshoots Full Backup")) {
                    Label("Export Full Backup", systemImage: "externaldrive")
                }
            } else {
                Text(history.loadError ?? "")
                ShareLink(item: ReflectionRecoveryExport(url: history.saveURL), preview: SharePreview("Reflection Recovery File")) {
                    Label("Export Reflection Recovery File", systemImage: "externaldrive.badge.exclamationmark")
                }
            }
            Button { importFullBackup = true; showImporter = true } label: {
                Label("Restore Full Backup", systemImage: "arrow.clockwise.icloud")
            }
            Button(role: .destructive) { showDeleteAllConfirmation = true } label: {
                Label("Delete All Decisions", systemImage: "trash")
            }
            .disabled(store.decisions.isEmpty && history.readings.isEmpty && history.loadError == nil)
            .confirmationDialog("Delete all decisions and saved reflections?", isPresented: $showDeleteAllConfirmation, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) { perform { try coordinator.deleteAll() } }
            } message: {
                Text("This removes all decisions, saved readings, and their retained evidence. It also cancels reminders. Export a full backup first to keep a copy.")
            }
        } header: { Text("Data") } footer: {
            Text("Export Decisions saves journal entries only. A full backup includes saved reflections and their evidence. Import replaces data; it does not merge.")
        }
        .listRowBackground(Color.offshootCardBackground)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in handleImport(result) }
        .confirmationDialog(pendingBackup == nil ? "Replace decisions and clear saved reflections?" : "Replace all data with this full backup?", isPresented: Binding(
            get: { pendingImport != nil || pendingBackup != nil },
            set: { if !$0 { pendingImport = nil; pendingBackup = nil } }
        ), titleVisibility: .visible) {
            Button("Replace Data", role: .destructive) {
                if let pendingBackup { perform { try coordinator.restore(pendingBackup) } }
                else if let pendingImport { perform { try coordinator.importDecisions(pendingImport) } }
                pendingImport = nil; pendingBackup = nil
            }
        } message: {
            Text(pendingBackup == nil
                 ? "Decision-only import replaces current decisions and removes all saved reflections. Old reminders are replaced. Export a full backup first."
                 : "This replaces all decisions, saved readings, retained evidence, and reminders. Export a full backup or recovery file first.")
        }
        .alert("Data operation failed", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(importError ?? "") }
    }
    private var coordinator: JournalDataCoordinator { JournalDataCoordinator(store: store, history: history) }
    private func perform(_ work: () throws -> Void) {
        do { try work() }
        catch { importError = "The data could not be replaced. Your previous files were retained. Check storage and file access, then try again." }
    }
    private func handleImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            if importFullBackup {
                let backup = try ReflectionBackup.decode(Data(contentsOf: url))
                if store.decisions.isEmpty && history.readings.isEmpty && history.loadError == nil { perform { try coordinator.restore(backup) } }
                else { pendingBackup = backup }
            } else {
                let incoming = try DecisionsImport.read(from: url)
                if store.decisions.isEmpty && history.readings.isEmpty && history.loadError == nil { perform { try coordinator.importDecisions(incoming) } }
                else { pendingImport = incoming }
            }
        } catch {
            if (error as? CocoaError)?.code != .userCancelled { importError = "This file could not be imported. Choose a valid Offshoots export for the selected action." }
        }
    }
}
