internal import SwiftUI

// MARK: - App Info Model

struct LowEffortApp: Identifiable {
    let name: String
    let iconName: String
    let appStoreID: String
    /// The App Store URL slug when it differs from the lowercased, hyphenated name
    /// (Task(ed) drops its parentheses; Tucked's name carries a subtitle).
    let slug: String?

    init(name: String, iconName: String, appStoreID: String, slug: String? = nil) {
        self.name = name
        self.iconName = iconName
        self.appStoreID = appStoreID
        self.slug = slug
    }

    var id: String { appStoreID }

    var appStoreURL: URL? {
        let urlSlug = slug ?? name.lowercased().replacingOccurrences(of: " ", with: "-")
        return URL(string: "https://apps.apple.com/us/app/\(urlSlug)/id\(appStoreID)")
    }
}

// MARK: - App Catalog

/// The other released Low Effort Apps. Offshoots is not listed, so the section never shows the app itself.
enum LowEffortApps {
    // Icons have light and dark variants where the app's own icon does.
    static let tasked = LowEffortApp(name: "Task(ed)", iconName: "tasked", appStoreID: "6755186421", slug: "task-ed")
    static let everyPaw = LowEffortApp(name: "EveryPaw", iconName: "everypaw", appStoreID: "6754781167")
    static let aisleWise = LowEffortApp(name: "AisleWise", iconName: "aislewise", appStoreID: "6755057084")
    static let weatherInWords = LowEffortApp(name: "Weather in Words", iconName: "weatherinwords", appStoreID: "6806063498")
    // Tucked has one icon for both modes.
    static let tucked = LowEffortApp(name: "Tucked", iconName: "tucked", appStoreID: "6792490401", slug: "tucked-stuff-for-whenever")

    static let all: [LowEffortApp] = [
        tasked, everyPaw, aisleWise, weatherInWords, tucked,
    ]
}

// MARK: - About Section View

struct AboutSectionView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        Group {
            // MARK: - We Also Make Section
            Section {
                ForEach(LowEffortApps.all) { app in
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
                Link(destination: URL(string: "https://www.loweffortapps.app")!) {
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
                Link(destination: URL(string: "https://www.loweffortapps.app/privacy/")!) {
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
            AboutSectionView()
        }
        .navigationTitle("Settings")
    }
}
