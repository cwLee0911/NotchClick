import Foundation
import SwiftUI

final class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    private init() {
        normalizeLanguage()
        normalizeDefaultTab()
        normalizeMusicProvider()
    }

    func normalizeLanguage() {
        let normalized = AppLanguage.normalizedCode(language)
        if language != normalized {
            language = normalized
        }
    }

    func normalizeDefaultTab() {
        let normalized = PanelTab.normalizedRawValue(defaultTab)
        if defaultTab != normalized {
            defaultTab = normalized
        }
    }

    func normalizeMusicProvider() {
        let normalized = MusicProvider.fromStored(musicProvider)?.rawValue ?? ""
        if musicProvider != normalized {
            musicProvider = normalized
        }
    }

    @AppStorage("nd_launch_at_login") var launchAtLogin = false
    @AppStorage("nd_hover_delay") var hoverDelay = 0.18
    @AppStorage("nd_dismiss_delay") var dismissDelay = 0.4
    @AppStorage("nd_default_tab") var defaultTab = "Launcher"
    @AppStorage("nd_music_provider") var musicProvider = ""
    @AppStorage("nd_language") var language = AppLanguage.defaultCode
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"

    var id: String { rawValue }
    var nativeTitle: String { "English" }

    static var defaultCode: String {
        english.rawValue
    }

    static func normalizedCode(_ code: String?) -> String {
        english.rawValue
    }

    static func current(_ code: String) -> AppLanguage {
        .english
    }
}

enum L10n {
    enum Key: String {
        case launcher, music
        case addApp, chooseApp, searchInstalledApps, noAppsFound, noMatches
        case addAppHelp, launcherFullHelp
        case setMusicApp, chooseMusicApp
        case openMusic, openSpotify
        case appleMusicSubtitle, spotifySubtitle
        case appNotRunning, nothingPlaying, permissionNeeded
        case appNotRunningMessage, nothingPlayingMessage
        case general, about, behavior, launchAtLogin, defaultTab
        case notch, notchDescription, aboutDescription
        case launchAtLoginUpdateFailed, launchAtLoginNeedsApproval, launchAtLoginUnavailable, launchAtLoginStatusUnknown
        case version
    }

    static func tr(_ key: Key, _ languageCode: String) -> String {
        switch key {
        case .launcher: return "Launcher"
        case .music: return "Music"
        case .addApp: return "Add App"
        case .chooseApp: return "Choose an app"
        case .searchInstalledApps: return "Search installed apps..."
        case .noAppsFound: return "No apps found"
        case .noMatches: return "No matches"
        case .addAppHelp: return "Add App"
        case .launcherFullHelp: return "Launcher is full"
        case .setMusicApp: return "Choose a music app"
        case .chooseMusicApp: return "Choose Apple Music or Spotify above, then this screen will switch to that player automatically."
        case .openMusic: return "Open Music"
        case .openSpotify: return "Open Spotify"
        case .appleMusicSubtitle: return "Built into macOS"
        case .spotifySubtitle: return "Control the Spotify app"
        case .appNotRunning: return "isn't running"
        case .nothingPlaying: return "Nothing playing"
        case .permissionNeeded: return "Permission needed"
        case .appNotRunningMessage: return "Launch the app to show the current song and playback controls."
        case .nothingPlayingMessage: return "Start a song and it will appear here."
        case .general: return "General"
        case .about: return "About"
        case .behavior: return "Behavior"
        case .launchAtLogin: return "Launch at login"
        case .defaultTab: return "Default tab"
        case .notch: return "Notch"
        case .notchDescription: return "Open NotchClick by clicking the top-center notch target."
        case .aboutDescription: return "A focused notch panel for macOS.\nApp launcher, Apple Music, and Spotify."
        case .launchAtLoginUpdateFailed: return "Couldn't update launch at login right now."
        case .launchAtLoginNeedsApproval: return "Approve NotchClick in Login Items to finish enabling launch at login."
        case .launchAtLoginUnavailable: return "Launch at login isn't available in this build."
        case .launchAtLoginStatusUnknown: return "Couldn't determine the current launch at login status."
        case .version: return "Version"
        }
    }

    static func musicAutomationMessage(appName: String, _ languageCode: String) -> String {
        "Allow NotchClick to control \(appName) in System Settings > Privacy & Security > Automation."
    }

    static func openAppAndRetryMessage(appName: String, _ languageCode: String) -> String {
        "Open \(appName) and try again."
    }

    static func musicCommunicationMessage(appName: String, detail: String?, _ languageCode: String) -> String {
        detail.map { "Couldn't communicate with \(appName): \($0)" }
            ?? "Couldn't communicate with \(appName) right now."
    }
}

extension MusicProvider {
    func localizedSubtitle(_ languageCode: String) -> String {
        switch self {
        case .appleMusic: return L10n.tr(.appleMusicSubtitle, languageCode)
        case .spotify: return L10n.tr(.spotifySubtitle, languageCode)
        }
    }

    func localizedOpenActionTitle(_ languageCode: String) -> String {
        switch self {
        case .appleMusic: return L10n.tr(.openMusic, languageCode)
        case .spotify: return L10n.tr(.openSpotify, languageCode)
        }
    }
}

extension PanelTab {
    static func fromStored(_ value: String) -> PanelTab {
        PanelTab(rawValue: normalizedRawValue(value)) ?? .launcher
    }

    static func normalizedRawValue(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let folded = trimmed
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()

        if folded == "launcher" || folded == "launch" {
            return launcher.rawValue
        }

        if folded == "music" || folded.contains("music") {
            return music.rawValue
        }

        return launcher.rawValue
    }

    func localizedTitle(_ languageCode: String) -> String {
        switch self {
        case .launcher: return L10n.tr(.launcher, languageCode)
        case .music: return L10n.tr(.music, languageCode)
        }
    }
}
