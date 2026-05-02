import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowManager: NotchWindowManager?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        windowManager = NotchWindowManager()
        windowManager?.setup()
        setupStatusItem()
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusItem = nil
        windowManager?.teardown()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "rectangle.topthird.inset.filled",
            accessibilityDescription: "NotchClick"
        ) ?? NSImage(systemSymbolName: "rectangle", accessibilityDescription: "NotchClick")
        item.button?.image?.isTemplate = true
        item.button?.toolTip = "NotchClick"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Open NotchClick",
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
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
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
