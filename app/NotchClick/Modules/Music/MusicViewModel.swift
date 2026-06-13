import SwiftUI
import AppKit

enum MusicProvider: String, CaseIterable, Identifiable {
    case appleMusic
    case spotify

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appleMusic: return "Apple Music"
        case .spotify:    return "Spotify"
        }
    }

    var symbolName: String {
        switch self {
        case .appleMusic: return "music.note"
        case .spotify:    return "waveform"
        }
    }

    var accentColor: Color {
        switch self {
        case .appleMusic: return Color(red: 1.0, green: 0.27, blue: 0.45)
        case .spotify:    return Color(red: 0.18, green: 0.8, blue: 0.44)
        }
    }
}

final class MusicViewModel: ObservableObject {
    @Published var selectedProvider: MusicProvider? {
        didSet {
            guard oldValue != selectedProvider else { return }
            UserPreferences.shared.musicProvider = selectedProvider?.rawValue ?? ""
        }
    }
    @Published var track: MusicTrack?
    @Published var artworkImage: NSImage?
    @Published var isSelectedAppRunning = false
    @Published var errorMessage: String?

    private var timer: Timer?
    private var isPolling = false
    private var artworkURL: URL?
    private var artworkTask: Task<Void, Never>?

    init() {
        selectedProvider = MusicProvider.fromStored(UserPreferences.shared.musicProvider)
        UserPreferences.shared.musicProvider = selectedProvider?.rawValue ?? ""
    }

    deinit {
        timer?.invalidate()
        artworkTask?.cancel()
    }

    // MARK: Selection

    func selectProvider(_ provider: MusicProvider) {
        guard selectedProvider != provider else {
            refreshNow()
            return
        }

        selectedProvider = provider
        if isPolling {
            startPolling()
        } else {
            refreshNow()
        }
    }

    func restoreSavedProviderSelection() {
        let savedProvider = MusicProvider.fromStored(UserPreferences.shared.musicProvider)
        guard selectedProvider != savedProvider else {
            return
        }

        selectedProvider = savedProvider
        if isPolling {
            startPolling()
        } else {
            refreshNow()
        }
    }

    // MARK: Polling

    func startPolling() {
        isPolling = true
        timer?.invalidate()
        refreshNow()
        guard selectedProvider != nil else {
            timer = nil
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchTrack()
        }
    }

    func stopPolling() {
        isPolling = false
        timer?.invalidate()
        timer = nil
    }

    func refreshNow() {
        fetchTrack()
    }

    /// Runs on the main thread: the underlying `NSAppleScript` is not thread-safe, and
    /// because the main run loop is serial there is no overlapping-fetch to guard against.
    /// Only the artwork download (below) is moved off the main thread.
    private func fetchTrack() {
        guard let bridge = activeBridge else {
            resetPlaybackState()
            return
        }

        let provider = selectedProvider
        let isRunning = bridge.isRunning
        let snapshot = bridge.currentTrackSnapshot()

        guard selectedProvider == provider else { return }

        let newTrack = snapshot.track
        isSelectedAppRunning = isRunning
        track = newTrack
        errorMessage = snapshot.errorMessage

        if newTrack?.artworkURL != artworkURL {
            artworkURL = newTrack?.artworkURL
            loadArtwork(from: newTrack?.artworkURL)
        }

        if newTrack?.artworkURL == nil {
            artworkImage = nil
        }
    }

    private func resetPlaybackState() {
        artworkTask?.cancel()
        track = nil
        artworkImage = nil
        artworkURL = nil
        isSelectedAppRunning = false
        errorMessage = nil
    }

    private func loadArtwork(from url: URL?) {
        artworkTask?.cancel()

        guard let url else {
            artworkImage = nil
            return
        }

        artworkTask = Task { [weak self] in
            guard let self else { return }

            if let (data, _) = try? await URLSession.shared.data(from: url),
               let img = NSImage(data: data),
               !Task.isCancelled {
                await MainActor.run {
                    guard self.artworkURL == url else { return }
                    self.artworkImage = img
                }
            }
        }
    }

    // MARK: Controls

    func playPause() { runTransportAction { $0.playPause() } }
    func nextTrack() { runTransportAction { $0.nextTrack() } }
    func prevTrack() { runTransportAction { $0.prevTrack() } }
    func openSelectedApp() { activeBridge?.openApp() }

    var progressFraction: Double {
        guard let t = track, t.duration > 0 else { return 0 }
        return min(t.position / t.duration, 1.0)
    }

    var formattedPosition: String { formatTime(track?.position ?? 0) }
    var formattedDuration: String { formatTime(track?.duration ?? 0) }

    private var activeBridge: MusicAppBridge? {
        selectedProvider.map(bridge(for:))
    }

    private func bridge(for provider: MusicProvider) -> MusicAppBridge {
        switch provider {
        case .appleMusic: return AppleMusicBridge.shared
        case .spotify:    return SpotifyBridge.shared
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private func runTransportAction(_ action: (MusicAppBridge) -> String?) {
        guard let bridge = activeBridge else { return }
        let errorMessage = action(bridge)

        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = errorMessage
        }

        refreshNow()
    }
}

extension MusicProvider {
    static func fromStored(_ value: String) -> MusicProvider? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let provider = MusicProvider(rawValue: trimmed) {
            return provider
        }

        let folded = trimmed
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()

        if folded == "apple-music" || folded == "applemusic" || folded == "music" {
            return .appleMusic
        }

        if folded == "spotify" {
            return .spotify
        }

        return nil
    }
}
