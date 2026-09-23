//
//  SettingsView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 1/3/26.
//

internal import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: DecisionStore
    @AppStorage(ReminderManager.enabledKey) private var notificationsEnabled = true
    @State private var showTipJar = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Notifications
                Section {
                    Toggle("Follow-up Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, isEnabled in
                            if isEnabled {
                                ReminderManager.shared.requestAuthorization()
                                ReminderManager.shared.rescheduleAll(for: store.decisions)
                            } else {
                                ReminderManager.shared.cancelAllReminders()
                            }
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
                } header: {
                    Text("Data")
                }

                // MARK: - Appearance (Placeholder)
                Section {
                    HStack {
                        Text("App Theme")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("System")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("App Icon")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("Default")
                            .foregroundStyle(.secondary)
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
        .environmentObject(DecisionStore())
}
