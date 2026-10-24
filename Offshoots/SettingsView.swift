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

                SettingsDataSection()

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
                HindsightSettingsSection()

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


}

#Preview {
    SettingsView()
        .environment(DecisionStore())
        .environment(ReflectionCenter.make())
        .environment(HindsightAccess.make())
}
