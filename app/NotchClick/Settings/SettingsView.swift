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
    @State private var isLaunchAtLoginEnabled = UserPreferences.shared.launchAtLogin
    @State private var launchAtLoginStatusMessage: String?
    @AppStorage("nd_language") private var languageCode = AppLanguage.defaultCode

    var body: some View {
        Form {
            Section(L10n.tr(.behavior, languageCode)) {
                Toggle(
                    L10n.tr(.launchAtLogin, languageCode),
                    isOn: Binding(
                        get: { isLaunchAtLoginEnabled },
                        set: { toggleLoginItem($0) }
                    )
                )
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
        let snapshot = LaunchAtLoginService.setEnabled(enable, languageCode: languageCode)
        isLaunchAtLoginEnabled = snapshot.isEnabled
        prefs.launchAtLogin = snapshot.isEnabled
        launchAtLoginStatusMessage = snapshot.message
    }

    private func syncLaunchAtLoginStatus() {
        let snapshot = LaunchAtLoginService.currentSnapshot(languageCode: languageCode)
        isLaunchAtLoginEnabled = snapshot.isEnabled
        prefs.launchAtLogin = snapshot.isEnabled
        launchAtLoginStatusMessage = snapshot.message
    }
}

struct LaunchAtLoginSnapshot {
    let isEnabled: Bool
    let message: String?
}

enum LaunchAtLoginService {
    static func currentSnapshot(languageCode: String) -> LaunchAtLoginSnapshot {
        guard #available(macOS 13.0, *) else {
            return LaunchAtLoginSnapshot(
                isEnabled: false,
                message: L10n.tr(.launchAtLoginUnavailable, languageCode)
            )
        }

        switch SMAppService.mainApp.status {
        case .enabled:
            return LaunchAtLoginSnapshot(isEnabled: true, message: nil)
        case .requiresApproval:
            return LaunchAtLoginSnapshot(
                isEnabled: true,
                message: L10n.tr(.launchAtLoginNeedsApproval, languageCode)
            )
        case .notRegistered:
            return LaunchAtLoginSnapshot(isEnabled: false, message: nil)
        case .notFound:
            return LaunchAtLoginSnapshot(
                isEnabled: false,
                message: L10n.tr(.launchAtLoginUnavailable, languageCode)
            )
        @unknown default:
            return LaunchAtLoginSnapshot(
                isEnabled: UserPreferences.shared.launchAtLogin,
                message: L10n.tr(.launchAtLoginStatusUnknown, languageCode)
            )
        }
    }

    static func setEnabled(_ enabled: Bool, languageCode: String) -> LaunchAtLoginSnapshot {
        guard #available(macOS 13.0, *) else {
            return currentSnapshot(languageCode: languageCode)
        }

        do {
            switch (enabled, SMAppService.mainApp.status) {
            case (true, .enabled), (true, .requiresApproval),
                 (false, .notRegistered), (false, .notFound):
                break
            case (true, _):
                try SMAppService.mainApp.register()
            case (false, _):
                try SMAppService.mainApp.unregister()
            }
        } catch {
            let snapshot = currentSnapshot(languageCode: languageCode)
            return LaunchAtLoginSnapshot(
                isEnabled: snapshot.isEnabled,
                message: snapshot.message ?? L10n.tr(.launchAtLoginUpdateFailed, languageCode)
            )
        }

        return currentSnapshot(languageCode: languageCode)
    }

    static func reconcileStoredPreference() {
        guard #available(macOS 13.0, *) else {
            UserPreferences.shared.launchAtLogin = false
            return
        }

        if UserPreferences.shared.launchAtLogin && SMAppService.mainApp.status == .notRegistered {
            try? SMAppService.mainApp.register()
        }

        let snapshot = currentSnapshot(languageCode: UserPreferences.shared.language)
        UserPreferences.shared.launchAtLogin = snapshot.isEnabled
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
