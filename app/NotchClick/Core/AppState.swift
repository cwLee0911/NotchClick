import SwiftUI
import Combine

enum PanelTab: String, CaseIterable, Identifiable {
    case launcher = "Launcher"
    case music    = "Music"
    case center   = "Center"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .launcher: return "grid.circle.fill"
        case .music:    return "music.note"
        case .center:   return "switch.2"
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
    let systemVM         = SystemMonitor()
    let quickSettingsVM  = QuickSettingsViewModel()

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
        systemVM.stopPolling()
        musicVM.stopPolling()
        quickSettingsVM.stopPolling()
        quickSettingsVM.closeCenterPopup()
    }

    private func startPolling(for tab: PanelTab) {
        switch tab {
        case .launcher:
            break
        case .music:
            musicVM.startPolling()
        case .center:
            systemVM.startPolling()
        }
    }

    private func stopPolling(for tab: PanelTab) {
        switch tab {
        case .launcher:
            break
        case .music:
            musicVM.stopPolling()
        case .center:
            systemVM.stopPolling()
            quickSettingsVM.closeCenterPopup()
        }
    }
}
