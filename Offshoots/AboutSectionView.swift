internal import SwiftUI

// MARK: - App Info Model

struct LowEffortApp: Identifiable {
    let name: String
    let iconName: String
    let appStoreID: String

    var id: String { appStoreID }

    var appStoreURL: URL? {
        URL(string: "https://apps.apple.com/us/app/\(name.lowercased().replacingOccurrences(of: " ", with: "-"))/id\(appStoreID)")
    }
}

// MARK: - App Catalog

enum LowEffortApps {
   
    // Icons have light and dark variants in the asset catalog, like each app's own icon
    static let everyPaw = LowEffortApp(name: "EveryPaw", iconName: "everypaw", appStoreID: "6754781167")
    static let aisleWise = LowEffortApp(name: "AisleWise", iconName: "aislewise", appStoreID: "6755057084")
    static let tasked = LowEffortApp(name: "Task(ed)", iconName: "tasked", appStoreID: "6755186421")
   

    static let all: [LowEffortApp] = [
 everyPaw, aisleWise, tasked,  
    ]
}

// MARK: - About Section View

struct AboutSectionView: View {
    /// The bundle identifier prefix to exclude the current app from "Other Apps"
    /// Pass your app's name (e.g., "Task(ed)") to exclude it from the list
    let currentAppName: String?

    /// Optional custom list of apps to display. If nil, shows all apps except current.
    let appsToShow: [LowEffortApp]?

    init(currentAppName: String? = nil, appsToShow: [LowEffortApp]? = nil) {
        self.currentAppName = currentAppName
        self.appsToShow = appsToShow
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    private var otherApps: [LowEffortApp] {
        if let appsToShow = appsToShow {
            return appsToShow
        }

        guard let currentAppName = currentAppName else {
            return LowEffortApps.all
        }

        return LowEffortApps.all.filter { $0.name != currentAppName }
    }

    var body: some View {
        Group {
            // MARK: - We Also Make Section
            Section {
                ForEach(otherApps) { app in
                    OtherAppRow(app: app)
                }
            } header: {
                Text("We Also Make")
            }

            // MARK: - About Section
            Section {
                // Version & Build
                HStack {
                    Text("Version")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(appVersion) (\(buildNumber))")
                        .foregroundStyle(.secondary)
                }

                // Company Website
                Link(destination: URL(string: "https://www.loweffortapps.dev")!) {
                    HStack {
                        Text("Company Website")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Privacy Policy
                Link(destination: URL(string: "https://www.loweffortapps.dev/privacy-policy")!) {
                    HStack {
                        Text("Privacy Policy")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("About")
            }
        }
    }
}

// MARK: - Other App Row

struct OtherAppRow: View {
    let app: LowEffortApp

    var body: some View {
        Button(action: openAppStore) {
            HStack(spacing: 12) {
                Image(app.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(app.name)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func openAppStore() {
        guard let url = app.appStoreURL else { return }

        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        Form {
            AboutSectionView(currentAppName: "Task(ed)")
        }
        .navigationTitle("Settings")
    }
}
