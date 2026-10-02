//
//  SettingsView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 1/3/26.
//

internal import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(DecisionStore.self) private var store
    @AppStorage(ReminderManager.enabledKey) private var notificationsEnabled = true
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .system
    @State private var showDeleteAllConfirmation = false
    @State private var showImporter = false
    /// A file read and waiting for the user to confirm it may replace their decisions
    @State private var pendingImport: [Decision]?
    @State private var importError: String?

    private var deleteAllTitle: String {
        let count = store.decisions.count
        return count == 1 ? "Delete 1 decision?" : "Delete all \(count) decisions?"
    }

    private var replaceTitle: String {
        let current = store.decisions.count
        let incoming = pendingImport?.count ?? 0
        let currentText = current == 1 ? "1 decision" : "\(current) decisions"
        let incomingText = incoming == 1 ? "1 decision" : "\(incoming) decisions"
        return "Replace \(currentText) with \(incomingText) from the file?"
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Notifications
                Section {
                    Toggle("Follow-up Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, isEnabled in
                            store.setRemindersEnabled(isEnabled)
                        }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Receive reminders when it's time to review your decisions.")
                }
                .listRowBackground(Color.offshootCardBackground)

                // MARK: - Data
                Section {
                    HStack {
                        Text("Total Decisions")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(store.decisions.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Completed")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(store.completedDecisions.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Pending")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(store.pendingDecisions.count)")
                            .foregroundStyle(.secondary)
                    }

                    ShareLink(
                        item: DecisionsExport(decisions: store.decisions),
                        preview: SharePreview("Offshoots Decisions")
                    ) {
                        Label("Export Decisions", systemImage: "square.and.arrow.up")
                    }
                    .disabled(store.decisions.isEmpty)

                    Button {
                        showImporter = true
                    } label: {
                        Label("Import Decisions", systemImage: "square.and.arrow.down")
                    }
                    .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                        handleImport(result)
                    }
                    // Attached to the button, so the dialog points at this row
                    .confirmationDialog(
                        replaceTitle,
                        isPresented: Binding(
                            get: { pendingImport != nil },
                            set: { if !$0 { pendingImport = nil } }
                        ),
                        titleVisibility: .visible
                    ) {
                        Button("Replace Decisions", role: .destructive) {
                            if let pendingImport { store.replaceAll(with: pendingImport) }
                        }
                    } message: {
                        Text("Your current decisions and their reminders are removed. It cannot be undone. Export first to keep a copy.")
                    }
                    .alert(
                        "Import Failed",
                        isPresented: Binding(
                            get: { importError != nil },
                            set: { if !$0 { importError = nil } }
                        )
                    ) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text(importError ?? "")
                    }

                    Button(role: .destructive) {
                        showDeleteAllConfirmation = true
                    } label: {
                        Label("Delete All Decisions", systemImage: "trash")
                    }
                    .disabled(store.decisions.isEmpty)
                    // Attached to the button, so the dialog points at this row
                    .confirmationDialog(
                        deleteAllTitle,
                        isPresented: $showDeleteAllConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Delete All Decisions", role: .destructive) {
                            store.deleteAll()
                        }
                    } message: {
                        Text("This also cancels their reminders. It cannot be undone. Export first to keep a copy.")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Export saves a JSON file you can keep as a backup. Import restores one.")
                }
                .listRowBackground(Color.offshootCardBackground)

                // MARK: - Appearance
                Section {
                    Picker("App Theme", selection: $theme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.label).tag(theme)
                        }
                    }
                } header: {
                    Text("Appearance")
                }
                .listRowBackground(Color.offshootCardBackground)

                ReflectionSettingsSection()

                // MARK: - About Section
                AboutSectionView(currentAppName: "Offshoots")
                    // Row fills are set per section: on the Form itself the modifier has no effect
                    .listRowBackground(Color.offshootCardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Color.offshootBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    /// An empty store has nothing to lose, so the import applies at once. Otherwise it asks.
    private func handleImport(_ result: Result<URL, Error>) {
        let url: URL
        switch result {
        case .success(let picked):
            url = picked
        case .failure(let error):
            // Closing the picker is not an error
            if (error as? CocoaError)?.code != .userCancelled {
                importError = DecisionsImport.ImportError.unreadable.message
            }
            return
        }
        do {
            let imported = try DecisionsImport.read(from: url)
            if store.decisions.isEmpty {
                store.replaceAll(with: imported)
            } else {
                pendingImport = imported
            }
        } catch let error as DecisionsImport.ImportError {
            importError = error.message
        } catch {
            importError = DecisionsImport.ImportError.unreadable.message
        }
    }
}

#Preview {
    SettingsView()
        .environment(DecisionStore())
        .environment(ReflectionCenter.make())
}
