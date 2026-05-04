import SwiftUI
import Combine

enum PanelTab: String, CaseIterable, Identifiable {
    case launcher = "Launcher"
    case music    = "Music"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .launcher: return "grid.circle.fill"
        case .music:    return "music.note"
        }
    }
}

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var selectedTab: PanelTab {
        didSet {
            guard oldValue != selectedTab else { return }

            if isPolling {
                stopPolling(for: oldValue)
                startPolling(for: selectedTab)
            }
        }
    }

    let launcherVM       = LauncherViewModel()
    let musicVM          = MusicViewModel()

    private var isPolling = false

    private init() {
        UserPreferences.shared.normalizeLanguage()
        UserPreferences.shared.normalizeDefaultTab()

        selectedTab = PanelTab.fromStored(UserPreferences.shared.defaultTab)
        UserPreferences.shared.defaultTab = selectedTab.rawValue
    }

    func applyDefaultTab() {
        UserPreferences.shared.normalizeDefaultTab()
        selectedTab = PanelTab.fromStored(UserPreferences.shared.defaultTab)
    }

    func setDefaultTab(_ rawValue: String) {
        let tab = PanelTab.fromStored(rawValue)
        UserPreferences.shared.defaultTab = tab.rawValue
        selectedTab = tab
    }

    func startPolling() {
        guard !isPolling else {
            startPolling(for: selectedTab)
            return
        }

        isPolling = true
        startPolling(for: selectedTab)
    }

    func stopPolling() {
        guard isPolling else { return }

        isPolling = false
        musicVM.stopPolling()
    }

    private func startPolling(for tab: PanelTab) {
        switch tab {
        case .launcher:
            break
        case .music:
            musicVM.startPolling()
        }
    }

    private func stopPolling(for tab: PanelTab) {
        switch tab {
        case .launcher:
            break
        case .music:
            musicVM.stopPolling()
        }
    }
}
