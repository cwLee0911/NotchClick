import Foundation
import AppKit
import SwiftUI
import IOBluetooth

struct BluetoothDeviceItem: Identifiable, Equatable {
    let id: String
    let name: String
    let subtitle: String
    let icon: String
    let isConnected: Bool
}

enum CenterPopup: String, Identifiable, CaseIterable {
    case language
    var id: String { rawValue }

    var popupWidth: CGFloat {
        214
    }

    var popupHeight: CGFloat {
        138
    }

    /// Index of this popup's source card in the Controls tab row.
    var cardIndex: Int {
        0
    }
}

class QuickSettingsViewModel: ObservableObject {
    @Published var isBluetoothOn = false
    @Published var bluetoothStatusText = "Unavailable"
    @Published var bluetoothDevices: [BluetoothDeviceItem] = []
    @Published var isLoadingBluetoothDetails = false
    @Published var bluetoothActionDeviceID: String? = nil
    @Published var bluetoothErrorMessage: String? = nil

    /// Which Control-Center-style dropdown is currently shown (mutually exclusive).
    @Published var activeCenterPopup: CenterPopup? = nil

    var isLanguagePopupVisible:  Bool { activeCenterPopup == .language }

    var protectedModalActionRunner: (((() -> Void)) -> Void)?

    private var timer: Timer?
    private let refreshQueue = DispatchQueue(
        label: "com.notchclick.quick-settings-refresh",
        qos: .utility
    )
    private let refreshLock = NSLock()
    private var refreshInFlight = false

    init() {}

    // MARK: - Polling

    func startPolling() {
        timer?.invalidate()
        refreshAll()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.refreshAll()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
        refreshLock.lock()
        refreshInFlight = false
        refreshLock.unlock()
    }

    func refreshNow() {
        refreshAll()
    }

    private func refreshAll() {
        refreshLock.lock()
        guard !refreshInFlight else {
            refreshLock.unlock()
            return
        }
        refreshInFlight = true
        refreshLock.unlock()

        refreshQueue.async { [weak self] in
            guard let self else { return }

            let bt   = self.readBluetoothStatus()

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                self.isBluetoothOn = bt.isOn
                self.bluetoothStatusText = bt.label

                self.refreshLock.lock()
                self.refreshInFlight = false
                self.refreshLock.unlock()
            }
        }
    }

    // MARK: - Bluetooth

    func loadBluetoothDetails() {
        guard !isLoadingBluetoothDetails else { return }

        bluetoothErrorMessage = nil
        isLoadingBluetoothDetails = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let devices = self?.readBluetoothDevices() ?? []

            DispatchQueue.main.async {
                self?.bluetoothDevices = devices
                self?.isLoadingBluetoothDetails = false
            }
        }
    }

    private func readBluetoothStatus() -> (isOn: Bool, label: String) {
        guard let controller = IOBluetoothHostController.default() else {
            return (false, "Unavailable")
        }

        let isOn = controller.powerState == kBluetoothHCIPowerStateON
        return (isOn, isOn ? "On" : "Off")
    }

    /// Connect / disconnect a paired Bluetooth device.
    func toggleBluetoothDevice(_ item: BluetoothDeviceItem) {
        guard isBluetoothOn else {
            bluetoothErrorMessage = "Turn Bluetooth on in System Settings before managing devices."
            return
        }

        let address = item.id
        let shouldConnect = !item.isConnected
        DispatchQueue.main.async { [weak self] in
            self?.bluetoothActionDeviceID = item.id
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            var handled = false

            if let device = IOBluetoothDevice(addressString: address) {
                if shouldConnect {
                    if device.openConnection() == kIOReturnSuccess {
                        handled = true
                    }
                } else {
                    if device.closeConnection() == kIOReturnSuccess {
                        handled = true
                    }
                }
            }

            DispatchQueue.main.async {
                if handled {
                    self.bluetoothErrorMessage = nil
                } else {
                    self.bluetoothErrorMessage = shouldConnect
                        ? "Couldn't connect to \(item.name)."
                        : "Couldn't disconnect \(item.name)."
                }
                self.scheduleRefresh(after: 0.8)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    self.loadBluetoothDetails()
                }
                self.bluetoothActionDeviceID = nil
            }
        }
    }

    private func readBluetoothDevices() -> [BluetoothDeviceItem] {
        let paired = IOBluetoothDevice.pairedDevices()
            .compactMap { $0 as? IOBluetoothDevice }

        return paired
            .map { device in
                BluetoothDeviceItem(
                    id: device.addressString,
                    name: device.nameOrAddress,
                    subtitle: device.isConnected() ? "Connected" : "Paired",
                    icon: bluetoothIcon(for: device.nameOrAddress),
                    isConnected: device.isConnected()
                )
            }
            .sorted { lhs, rhs in
                if lhs.isConnected != rhs.isConnected {
                    return lhs.isConnected && !rhs.isConnected
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .prefix(7)
            .map { $0 }
    }

    func openBluetoothSettings() {
        openSystemSettings([
            "x-apple.systempreferences:com.apple.BluetoothSettings",
            "x-apple.systempreferences:com.apple.preference.bluetooth"
        ])
    }

    // MARK: - Center popups

    /// Change the currently visible center popup (pass nil to close all).
    /// Opening a different popup animates the close/open transition.
    func setCenterPopup(_ popup: CenterPopup?) {
        guard activeCenterPopup != popup else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
            activeCenterPopup = popup
        }

    }

    /// Close whatever center popup is open. Safe to call at any time.
    func closeCenterPopup() {
        setCenterPopup(nil)
    }

    func toggleCenterPopup(_ popup: CenterPopup) {
        setCenterPopup(activeCenterPopup == popup ? nil : popup)
    }

    func toggleLanguagePopup()  { toggleCenterPopup(.language) }

    // MARK: - Helpers

    private func scheduleRefresh(after delay: TimeInterval = 0.45) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.refreshAll()
        }
    }

    private func openSystemSettings(_ candidates: [String]) {
        for candidate in candidates {
            guard let url = URL(string: candidate) else { continue }
            if NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    private func bluetoothIcon(for deviceName: String) -> String {
        let lowercase = deviceName.lowercased()

        if lowercase.contains("airpods") {
            return "airpodspro"
        }
        if lowercase.contains("keyboard") || lowercase.contains("kb") {
            return "keyboard"
        }
        if lowercase.contains("headphone") || lowercase.contains("sony") || lowercase.contains("wh-") {
            return "headphones"
        }
        if lowercase.contains("watch") {
            return "applewatch"
        }
        if lowercase.contains("iphone") || lowercase.contains("ipad") {
            return "iphone"
        }

        return "wave.3.right.circle"
    }
}
