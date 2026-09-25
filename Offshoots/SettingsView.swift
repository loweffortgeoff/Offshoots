//
//  SettingsView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 1/3/26.
//

internal import SwiftUI

struct SettingsView: View {
    @Environment(DecisionStore.self) private var store
    @AppStorage(ReminderManager.enabledKey) private var notificationsEnabled = true
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .system
    @State private var showTipJar = false
    @State private var showDeleteAllConfirmation = false

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

                    Button(role: .destructive) {
                        showDeleteAllConfirmation = true
                    } label: {
                        Label("Delete All Decisions", systemImage: "trash")
                    }
                    .disabled(store.decisions.isEmpty)
                    // Attached to the button, so the dialog points at this row
                    .confirmationDialog(
                        "Delete all \(store.decisions.count) decisions?",
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
                    Text("Export saves a JSON file you can keep as a backup.")
                }

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

                // MARK: - Support
                Section {
                    Button {
                        showTipJar = true
                    } label: {
                        HStack {
                            Label("Tip Jar", systemImage: "heart.fill")
                                .foregroundStyle(.pink)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Support")
                }

                // MARK: - About Section
                AboutSectionView(currentAppName: "Offshoots")
            }
            .listRowBackground(Color.offshootCardBackground)
            .scrollContentBackground(.hidden)
            .background(Color.offshootBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showTipJar) {
                TipJarView()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(DecisionStore())
}
