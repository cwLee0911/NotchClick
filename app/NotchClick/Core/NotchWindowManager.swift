import AppKit
import SwiftUI

// MARK: - Dimensions

enum NotchDimensions {
    private static let defaultNotchWidth: CGFloat = 185
    private static let defaultNotchHeight: CGFloat = 32
    static let triggerHorizontalPadding: CGFloat = 36
    static let triggerExtraHeight: CGFloat = 12
    static let minimumTriggerWidth: CGFloat = 240
    static let minimumTriggerHeight: CGFloat = 44
    static let expandedClickToleranceX: CGFloat = 24
    static let expandedClickToleranceY: CGFloat = 16

    // Collapsed — matches the real notch exactly when possible
    static var notchWidth:  CGFloat = defaultNotchWidth
    static var notchHeight: CGFloat = defaultNotchHeight

    // Expanded (panel)
    static let expandedWidth:  CGFloat = 540
    static let expandedHeight: CGFloat = 250
    static let expandedContentTopInset: CGFloat = 10

    // Window always sized to the maximum extent (stays fixed; content morphs)
    static let windowWidth:  CGFloat = 600
    static let windowHeight: CGFloat = expandedHeight

    /// Measure the real notch from the screen and cache into notchWidth / notchHeight
    static func calibrate(from screen: NSScreen) {
        notchWidth = defaultNotchWidth
        notchHeight = defaultNotchHeight

        let topInset = screen.safeAreaInsets.top
        guard topInset > 0 else { return }

        if (20...90).contains(topInset) {
            notchHeight = topInset
        }

        guard
            let leftArea = screen.auxiliaryTopLeftArea,
            let rightArea = screen.auxiliaryTopRightArea
        else {
            return
        }

        // The actual notch width is the gap between the two safe menu-bar areas.
        // Ignore implausible values so non-notched displays do not become a full-width trigger.
        let measured = rightArea.minX - leftArea.maxX
        let maximumPlausibleWidth = min(CGFloat(420), screen.frame.width * 0.35)
        if measured >= 120, measured <= maximumPlausibleWidth {
            notchWidth = measured
        }
    }
}

// MARK: - Panel Window

final class NotchPanelWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    init(screen: NSScreen, manager: NotchWindowManager) {
        let frame = Self.frame(for: screen)
        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        isOpaque           = false
        backgroundColor    = .clear
        hasShadow          = false          // shadow is rendered via SwiftUI
        level              = .init(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        isMovable          = false
        ignoresMouseEvents = false

        let rootView = NotchPanelView()
            .environmentObject(AppState.shared)
            .environmentObject(manager)
        contentView = FirstMouseHostingView(rootView: rootView)
        orderFrontRegardless()
    }

    static func frame(for screen: NSScreen) -> CGRect {
        let frame = screen.frame
        let w = NotchDimensions.windowWidth
        let h = NotchDimensions.windowHeight
        return CGRect(
            x: frame.midX - (w / 2),
            y: frame.maxY - h,   // anchor to TOP of screen
            width: w,
            height: h
        )
    }
}

private final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }

    required init(rootView: Content) {
        super.init(rootView: rootView)
        clearBacking()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        clearBacking()
    }

    override func layout() {
        super.layout()
        clearBacking()
    }

    private func clearBacking() {
        wantsLayer = true
        layer?.isOpaque = false
        layer?.backgroundColor = NSColor.clear.cgColor
        window?.isOpaque = false
        window?.backgroundColor = .clear
    }
}

final class NotchTriggerWindow: NSPanel {
    init(frame: CGRect, manager: NotchWindowManager) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .init(rawValue: NSWindow.Level.statusBar.rawValue + 2)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        isMovable = false
        ignoresMouseEvents = false
        contentView = NotchTriggerView(manager: manager)
        orderFrontRegardless()
    }
}

private final class NotchTriggerView: NSView {
    weak var manager: NotchWindowManager?

    init(manager: NotchWindowManager) {
        self.manager = manager
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        manager?.openFromNotchClick()
    }
}

// MARK: - Window Manager

final class NotchWindowManager: ObservableObject {
    @Published var isExpanded = false

    private var panelWindow: NotchPanelWindow?
    private var triggerWindow: NotchTriggerWindow?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var workspaceObservers: [Any] = []
    private var preferredScreenID: CGDirectDisplayID?

    // Visible notch shape. Kept exact so clicking the top strip toggles closed when expanded.
    private var visibleNotchZone: NSRect = .zero
    // Trigger zone. Slightly larger than the visible notch so opening is forgiving.
    private var clickZone: NSRect = .zero
    // Expanded zone: where the panel extends when open
    private var expandedZone: NSRect = .zero

    func setup() {
        guard let screen = defaultScreen else { return }

        preferredScreenID = displayID(for: screen)
        NotchDimensions.calibrate(from: screen)
        panelWindow = NotchPanelWindow(screen: screen, manager: self)
        rebuildZones(screen: screen)
        triggerWindow = NotchTriggerWindow(frame: clickZone, manager: self)
        startClickTracking()
        startWorkspaceTracking()
        refreshWindowVisibility()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func teardown() {
        stopClickTracking()
        stopWorkspaceTracking()
        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        triggerWindow?.close()
        triggerWindow = nil
        panelWindow?.close()
        panelWindow = nil
    }

    func openFromNotchClick() {
        AppState.shared.launcherVM.reloadFromStorageIfChanged()

        if let screen = screenContaining(point: NSEvent.mouseLocation) ?? triggerWindow?.screen {
            moveWindows(to: screen)
        }

        expand()
    }

    // MARK: Zones

    private func rebuildZones(screen: NSScreen) {
        let frame = screen.frame
        let nw   = NotchDimensions.notchWidth
        let nh   = NotchDimensions.notchHeight

        visibleNotchZone = NSRect(
            x: frame.midX - (nw / 2),
            y: frame.maxY - nh,
            width: nw,
            height: nh
        )

        let triggerWidth = min(
            frame.width,
            max(nw + (NotchDimensions.triggerHorizontalPadding * 2), NotchDimensions.minimumTriggerWidth)
        )
        let triggerHeight = max(
            nh + NotchDimensions.triggerExtraHeight,
            NotchDimensions.minimumTriggerHeight
        )
        let triggerX = min(
            max(frame.midX - (triggerWidth / 2), frame.minX),
            frame.maxX - triggerWidth
        )

        clickZone = NSRect(
            x: triggerX,
            y: frame.maxY - triggerHeight,
            width: triggerWidth,
            height: triggerHeight
        )

        let ew = NotchDimensions.expandedWidth
        let eh = NotchDimensions.expandedHeight
        expandedZone = NSRect(
            x: frame.midX - (ew / 2),
            y: frame.maxY - eh,
            width: ew,
            height: eh
        )
    }

    // MARK: Click Tracking

    private func startClickTracking() {
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown]

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handleClick(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handleClick(event)
            return event
        }
    }

    private func stopClickTracking() {
        if let m = globalMonitor { NSEvent.removeMonitor(m) }
        if let m = localMonitor  { NSEvent.removeMonitor(m) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handleClick(_ event: NSEvent) {
        let loc = NSEvent.mouseLocation

        guard isExpanded else {
            return
        }

        if event.type == .leftMouseDown && visibleNotchZone.contains(loc) {
            collapse()
            return
        }

        let insidePanel = expandedZone
            .insetBy(
                dx: -NotchDimensions.expandedClickToleranceX,
                dy: -NotchDimensions.expandedClickToleranceY
            )
            .contains(loc)

        if !insidePanel {
            collapse()
        }
    }

    // MARK: Workspace State

    private func startWorkspaceTracking() {
        let center = NSWorkspace.shared.notificationCenter

        workspaceObservers.append(
            center.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleActiveSpaceDidChange()
            }
        )

        workspaceObservers.append(
            center.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleWorkspaceVisibilityChange()
            }
        )
    }

    private func stopWorkspaceTracking() {
        let center = NSWorkspace.shared.notificationCenter
        for observer in workspaceObservers {
            center.removeObserver(observer)
        }
        workspaceObservers.removeAll()
    }

    private var defaultScreen: NSScreen? {
        screenContaining(point: NSEvent.mouseLocation)
        ?? NSScreen.main
        ?? NSScreen.screens.first
    }

    private var currentScreen: NSScreen? {
        if let preferredScreenID, let screen = screen(for: preferredScreenID) {
            return screen
        }

        return panelWindow?.screen ?? triggerWindow?.screen ?? defaultScreen
    }

    private func updateEnvironmentState() {
        refreshWindowVisibility()
    }

    private func handleActiveSpaceDidChange() {
        AppState.shared.launcherVM.reloadFromStorageIfChanged()

        if let screen = screenContaining(point: NSEvent.mouseLocation) ?? currentScreen ?? defaultScreen {
            moveWindows(to: screen)
        } else {
            handleWorkspaceVisibilityChange()
        }

        schedulePostSpaceChangeRefresh()
    }

    private func handleWorkspaceVisibilityChange() {
        reapplyAllSpacesBehavior()
        updateEnvironmentState()
    }

    private func schedulePostSpaceChangeRefresh() {
        let delays: [TimeInterval] = [0.08, 0.28]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.handleWorkspaceVisibilityChange()
            }
        }
    }

    private func reapplyAllSpacesBehavior() {
        panelWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        triggerWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
    }

    private func screenContaining(point: NSPoint) -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) }
    }

    private func displayID(for screen: NSScreen) -> CGDirectDisplayID? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        guard let screenNumber = screen.deviceDescription[key] as? NSNumber else { return nil }
        return CGDirectDisplayID(screenNumber.uint32Value)
    }

    private func screen(for displayID: CGDirectDisplayID) -> NSScreen? {
        NSScreen.screens.first { screen in
            self.displayID(for: screen) == displayID
        }
    }

    private func moveWindows(to screen: NSScreen) {
        preferredScreenID = displayID(for: screen)
        NotchDimensions.calibrate(from: screen)
        rebuildZones(screen: screen)

        if let panelWindow {
            panelWindow.setFrame(NotchPanelWindow.frame(for: screen), display: true)
        }

        triggerWindow?.setFrame(clickZone, display: true)
        updateEnvironmentState()
    }

    private func refreshWindowVisibility() {
        guard let panelWindow, let triggerWindow else { return }

        panelWindow.ignoresMouseEvents = !isExpanded

        if isExpanded {
            panelWindow.orderFrontRegardless()
            triggerWindow.orderOut(nil)
            return
        }

        panelWindow.orderFrontRegardless()
        triggerWindow.setFrame(clickZone, display: true)
        triggerWindow.orderFrontRegardless()
    }

    // MARK: Expand / Collapse

    private func expand() {
        guard !isExpanded else { return }

        panelWindow?.makeKeyAndOrderFront(nil)
        panelWindow?.ignoresMouseEvents = false
        triggerWindow?.orderOut(nil)
        NSApp.activate(ignoringOtherApps: true)

        AppState.shared.applyDefaultTab()
        AppState.shared.startPolling()
        withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
            isExpanded = true
        }
    }

    private func collapse() {
        guard isExpanded else {
            refreshWindowVisibility()
            return
        }

        AppState.shared.stopPolling()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
            isExpanded = false
        }

        refreshWindowVisibility()
    }

    // MARK: Screen Change

    @objc private func screensChanged() {
        guard let screen = currentScreen ?? defaultScreen else { return }
        moveWindows(to: screen)
    }
}
