import Foundation
import AppKit

struct MusicTrack {
    var name: String
    var artist: String
    var album: String
    var artworkURL: URL?
    var duration: Double
    var position: Double
    var isPlaying: Bool
}

protocol MusicAppBridge {
    var isRunning: Bool { get }
    func currentTrackSnapshot() -> MusicTrackSnapshot
    func playPause() -> String?
    func nextTrack() -> String?
    func prevTrack() -> String?
    func openApp()
}

private enum MusicDurationUnit {
    case seconds
    case milliseconds
}

struct MusicTrackSnapshot {
    var track: MusicTrack?
    var errorMessage: String?
}

final class AppleMusicBridge: MusicAppBridge {
    static let shared = AppleMusicBridge()
    private init() {}

    private let bundleIdentifier = "com.apple.Music"

    var isRunning: Bool {
        NSWorkspace.shared.runningApplications
            .contains { $0.bundleIdentifier == bundleIdentifier }
    }

    func currentTrackSnapshot() -> MusicTrackSnapshot {
        guard isRunning else {
            return MusicTrackSnapshot(track: nil, errorMessage: nil)
        }

        let script = """
        tell application "Music"
            if player state is stopped then return ""
            set t to current track
            set sep to "|||"
            return (name of t) & sep & (artist of t) & sep & (album of t) & sep & "" & sep & (duration of t as string) & sep & (player position as string) & sep & (player state as string)
        end tell
        """

        let result = MusicScriptRunner.runScript(script)
        return MusicTrackSnapshot(
            track: parseTrack(from: result.output, durationUnit: .seconds),
            errorMessage: result.userFacingMessage(for: "Music")
        )
    }

    func playPause() -> String? {
        run("tell application \"Music\" to playpause")
    }

    func nextTrack() -> String? {
        run("tell application \"Music\" to next track")
    }

    func prevTrack() -> String? {
        run("tell application \"Music\" to previous track")
    }

    func openApp() {
        MusicScriptRunner.openApplication(
            bundleIdentifier: bundleIdentifier,
            fallbackPath: "/System/Applications/Music.app"
        )
    }

    private func run(_ script: String) -> String? {
        MusicScriptRunner.runScript(script)
            .userFacingMessage(for: "Music")
    }
}

final class SpotifyBridge: MusicAppBridge {
    static let shared = SpotifyBridge()
    private init() {}

    private let bundleIdentifier = "com.spotify.client"

    var isRunning: Bool {
        NSWorkspace.shared.runningApplications
            .contains { $0.bundleIdentifier == bundleIdentifier }
    }

    func currentTrackSnapshot() -> MusicTrackSnapshot {
        guard isRunning else {
            return MusicTrackSnapshot(track: nil, errorMessage: nil)
        }

        let script = """
        tell application "Spotify"
            if player state is stopped then return ""
            set t to current track
            set sep to "|||"
            return (name of t) & sep & (artist of t) & sep & (album of t) & sep & (artwork url of t) & sep & (duration of t as string) & sep & (player position as string) & sep & (player state as string)
        end tell
        """

        let result = MusicScriptRunner.runScript(script)
        return MusicTrackSnapshot(
            track: parseTrack(
                from: result.output,
                durationUnit: .milliseconds
            ),
            errorMessage: result.userFacingMessage(for: "Spotify")
        )
    }

    func playPause() -> String? {
        run("tell application \"Spotify\" to playpause")
    }

    func nextTrack() -> String? {
        run("tell application \"Spotify\" to next track")
    }

    func prevTrack() -> String? {
        run("tell application \"Spotify\" to previous track")
    }

    func openApp() {
        MusicScriptRunner.openApplication(
            bundleIdentifier: bundleIdentifier,
            fallbackPath: "/Applications/Spotify.app"
        )
    }

    private func run(_ script: String) -> String? {
        MusicScriptRunner.runScript(script)
            .userFacingMessage(for: "Spotify")
    }
}

private struct MusicScriptResult {
    let output: String?
    let errorCode: Int?
    let errorMessage: String?

    func userFacingMessage(for appName: String) -> String? {
        guard let errorCode else { return nil }
        let languageCode = UserPreferences.shared.language

        switch errorCode {
        case -1743:
            return L10n.musicAutomationMessage(appName: appName, languageCode)
        case -600:
            return L10n.openAppAndRetryMessage(appName: appName, languageCode)
        default:
            let detail = errorMessage?.isEmpty == false ? errorMessage : nil
            return L10n.musicCommunicationMessage(
                appName: appName,
                detail: detail,
                languageCode
            )
        }
    }
}

private enum MusicScriptRunner {
    static func runScript(_ source: String) -> MusicScriptResult {
        var error: NSDictionary?
        let script = NSAppleScript(source: source)
        let result = script?.executeAndReturnError(&error)

        if let error {
            return MusicScriptResult(
                output: nil,
                errorCode: error[NSAppleScript.errorNumber] as? Int,
                errorMessage: error[NSAppleScript.errorMessage] as? String
            )
        }

        return MusicScriptResult(
            output: result?.stringValue,
            errorCode: nil,
            errorMessage: nil
        )
    }

    static func openApplication(bundleIdentifier: String, fallbackPath: String) {
        if let runningApplication = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == bundleIdentifier
        }) {
            if runningApplication.activate(options: [.activateAllWindows, .activateIgnoringOtherApps]) {
                return
            }
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            NSWorkspace.shared.openApplication(at: url, configuration: configuration)
            return
        }

        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: fallbackPath),
            configuration: configuration
        )
    }
}

private func parseTrack(from raw: String?, durationUnit: MusicDurationUnit) -> MusicTrack? {
    guard let raw, !raw.isEmpty else { return nil }

    let parts = raw.components(separatedBy: "|||")
    guard parts.count >= 7 else { return nil }

    let artworkString = parts[3].trimmingCharacters(in: .whitespacesAndNewlines)
    let parsedDuration = Double(parts[4].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    let duration: Double

    switch durationUnit {
    case .seconds:
        duration = parsedDuration
    case .milliseconds:
        duration = parsedDuration / 1000
    }

    return MusicTrack(
        name: parts[0],
        artist: parts[1],
        album: parts[2],
        artworkURL: artworkString.isEmpty ? nil : URL(string: artworkString),
        duration: duration,
        position: Double(parts[5].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0,
        isPlaying: parts[6].trimmingCharacters(in: .whitespacesAndNewlines) == "playing"
    )
}
