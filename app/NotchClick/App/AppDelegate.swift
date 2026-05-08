import AppKit
import SwiftUI

extension Notification.Name {
    static let notchClickOpenSettings = Notification.Name("NotchClickOpenSettings")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowManager: NotchWindowManager?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        windowManager = NotchWindowManager()
        windowManager?.setup()
        setupStatusItem()
        LaunchAtLoginService.reconcileStoredPreference()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettings),
            name: .notchClickOpenSettings,
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
        statusItem = nil
        windowManager?.teardown()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "rectangle.topthird.inset.filled",
                accessibilityDescription: "NotchClick"
            ) ?? NSImage(systemSymbolName: "rectangle", accessibilityDescription: "NotchClick")
            button.image?.isTemplate = true
            button.imagePosition = .imageLeft
            button.title = " NotchClick"
            button.toolTip = "NotchClick"
        }

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(NSMenuItem(
            title: "Open Panel",
            action: #selector(openNotchClick),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit NotchClick",
            action: #selector(quitNotchClick),
            keyEquivalent: "q"
        ))

        for item in menu.items {
            item.target = self
        }

        item.menu = menu
        statusItem = item
    }

    @objc private func openNotchClick() {
        windowManager?.openFromNotchClick()
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let controller = NSHostingController(
                rootView: SettingsView()
                    .environmentObject(AppState.shared)
            )
            let window = NSWindow(contentViewController: controller)
            window.title = "NotchClick Settings"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 460, height: 340)
            window.setFrameAutosaveName("NotchClick Settings")
            window.center()
            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitNotchClick() {
        NSApp.terminate(nil)
    }
}
