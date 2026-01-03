//
//  SettingsView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 1/3/26.
//

internal import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: DecisionStore
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Notifications
                Section {
                    Toggle("Follow-up Reminders", isOn: $notificationsEnabled)
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

                // MARK: - About Section
                AboutSectionView(currentAppName: "Offshoots")
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DecisionStore())
}
