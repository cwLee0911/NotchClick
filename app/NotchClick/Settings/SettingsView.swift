import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var prefs = UserPreferences.shared
    @EnvironmentObject var appState: AppState
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    var body: some View {
        TabView {
            GeneralTab(prefs: prefs, appState: appState)
                .tabItem { Label { Text(L10n.tr(.general, languageCode)) } icon: { Image(systemName: "gearshape") } }

            AboutTab()
                .tabItem { Label { Text(L10n.tr(.about, languageCode)) } icon: { Image(systemName: "info.circle") } }
        }
        .frame(width: 460, height: 340)
    }
}

// MARK: - General Tab

private struct GeneralTab: View {
    @ObservedObject var prefs: UserPreferences
    @ObservedObject var appState: AppState
    @State private var isSyncingLaunchAtLogin = false
    @State private var launchAtLoginStatusMessage: String?
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    var body: some View {
        Form {
            Section(L10n.tr(.behavior, languageCode)) {
                Toggle(L10n.tr(.launchAtLogin, languageCode), isOn: $prefs.launchAtLogin)
                    .onChange(of: prefs.launchAtLogin) { enabled in
                        guard !isSyncingLaunchAtLogin else { return }
                        toggleLoginItem(enabled)
                    }
                    .onAppear(perform: syncLaunchAtLoginStatus)

                Picker(L10n.tr(.defaultTab, languageCode), selection: $prefs.defaultTab) {
                    ForEach(PanelTab.allCases) { tab in
                        Text(tab.localizedTitle(languageCode)).tag(tab.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: prefs.defaultTab) { newValue in
                    appState.setDefaultTab(newValue)
                }

                if let launchAtLoginStatusMessage {
                    Text(launchAtLoginStatusMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Section(L10n.tr(.notch, languageCode)) {
                Text(L10n.tr(.notchDescription, languageCode))
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func toggleLoginItem(_ enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                syncLaunchAtLoginStatus()
            } catch {
                syncLaunchAtLoginStatus()
                if launchAtLoginStatusMessage == nil {
                    launchAtLoginStatusMessage = L10n.tr(.launchAtLoginUpdateFailed, languageCode)
                }
            }
        }
    }

    private func syncLaunchAtLoginStatus() {
        guard #available(macOS 13.0, *) else { return }

        isSyncingLaunchAtLogin = true
        defer { isSyncingLaunchAtLogin = false }

        switch SMAppService.mainApp.status {
        case .enabled:
            prefs.launchAtLogin = true
            launchAtLoginStatusMessage = nil
        case .requiresApproval:
            prefs.launchAtLogin = true
            launchAtLoginStatusMessage = L10n.tr(.launchAtLoginNeedsApproval, languageCode)
        case .notRegistered:
            prefs.launchAtLogin = false
            launchAtLoginStatusMessage = nil
        case .notFound:
            prefs.launchAtLogin = false
            launchAtLoginStatusMessage = L10n.tr(.launchAtLoginUnavailable, languageCode)
        @unknown default:
            launchAtLoginStatusMessage = L10n.tr(.launchAtLoginStatusUnknown, languageCode)
        }
    }
}

// MARK: - About Tab

private struct AboutTab: View {
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    private var appName: String {
        let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String

        return displayName ?? bundleName ?? "NotchClick"
    }

    private var versionText: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

        if buildNumber == shortVersion {
            return "\(L10n.tr(.version, languageCode)) \(shortVersion)"
        }

        return "\(L10n.tr(.version, languageCode)) \(shortVersion) (\(buildNumber))"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.topthird.inset.filled")
                .font(.system(size: 52))
                .foregroundStyle(.blue)

            VStack(spacing: 4) {
                Text(appName)
                    .font(.title2.bold())
                Text(versionText)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            Text(L10n.tr(.aboutDescription, languageCode))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
