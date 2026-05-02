import AppKit
import SwiftUI

// MARK: - Dimensions

enum NotchDimensions {
    // Collapsed — matches the real notch exactly when possible
    static var notchWidth:  CGFloat = 185
    static var notchHeight: CGFloat = 32

    // Expanded (panel)
    static let expandedWidth:  CGFloat = 540
    static let expandedHeight: CGFloat = 280
    static let expandedContentTopInset: CGFloat = 12

    // Controls dropdown below the panel (Control-Center-style)
    static let centerPopupWidth:  CGFloat = 280
    static let centerPopupHeight: CGFloat = 310
    static let centerStatusCardCount: CGFloat = 5
    /// Vertical spacing between panel bottom and popup top.
    /// Slight overlap keeps the dropdown visually attached without an outer shadow.
    static let centerPopupGap:    CGFloat = -4

    // Window always sized to the maximum extent (stays fixed; content morphs)
    static let windowWidth:  CGFloat = 600
    static let windowHeight: CGFloat = expandedHeight + centerPopupGap + centerPopupHeight + 16

    /// Measure the real notch from the screen and cache into notchWidth / notchHeight
    static func calibrate(from screen: NSScreen) {
        let topInset = screen.safeAreaInsets.top
        guard topInset > 0 else {
            notchWidth  = 185
            notchHeight = 32
            return
        }
        notchHeight = topInset

        // The actual notch width = total screen width − (left menu area + right menu area)
        let leftMaxX  = screen.auxiliaryTopLeftArea?.maxX  ?? 0
        let rightMinX = screen.auxiliaryTopRightArea?.minX ?? screen.frame.width
        let measured  = rightMinX - leftMaxX
        notchWidth    = measured > 100 ? measured : 185
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
    private var visibilityWorkItem: DispatchWorkItem?
    private var isFullscreenTriggerDisabled = false
    private var suppressOutsideClickHandling = false
    private var preferredScreenID: CGDirectDisplayID?

    // Tight hot zone: just the notch area itself
    private var notchZone: NSRect = .zero
    // Click zone aligned with the full visible collapsed notch.
    private var clickZone: NSRect = .zero
    // Expanded zone: where the panel extends when open
    private var expandedZone: NSRect = .zero

    func setup() {
        guard let screen = defaultScreen else { return }

        preferredScreenID = displayID(for: screen)
        NotchDimensions.calibrate(from: screen)
        panelWindow = NotchPanelWindow(screen: screen, manager: self)
        AppState.shared.quickSettingsVM.protectedModalActionRunner = { [weak self] action in
            guard let self else {
                action()
                return
            }
            self.performProtectedModalAction(action)
        }
        rebuildZones(screen: screen)
        triggerWindow = NotchTriggerWindow(frame: clickZone, manager: self)
        startClickTracking()
        startWorkspaceTracking()
        refreshWindowVisibility(hideCollapsedImmediately: true)
        updateEnvironmentState(hideCollapsedImmediately: true)

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
        visibilityWorkItem?.cancel()
        visibilityWorkItem = nil
        AppState.shared.quickSettingsVM.protectedModalActionRunner = nil
        triggerWindow?.close()
        triggerWindow = nil
        panelWindow?.close()
        panelWindow = nil
    }

    func openFromNotchClick() {
        AppState.shared.launcherVM.reloadFromStorageIfChanged()

        if let screen = screenContaining(point: NSEvent.mouseLocation) ?? triggerWindow?.screen {
            moveWindows(to: screen, hideCollapsedImmediately: true)
        }

        expand()
    }

    func performProtectedModalAction(_ action: () -> Void) {
        suppressOutsideClickHandling = true
        action()
        suppressOutsideClickHandling = false
    }

    // MARK: Zones

    private func rebuildZones(screen: NSScreen) {
        let frame = screen.frame
        let nw   = NotchDimensions.notchWidth
        let nh   = NotchDimensions.notchHeight

        notchZone = NSRect(
            x: frame.midX - (nw / 2),
            y: frame.maxY - nh,
            width: nw,
            height: nh
        )

        clickZone = notchZone

        let ew = NotchDimensions.expandedWidth
        let eh = NotchDimensions.expandedHeight
        expandedZone = NSRect(
            x: frame.midX - (ew / 2),
            y: frame.maxY - eh,
            width: ew,
            height: eh
        )
    }

    /// Screen-coord rect for the popup spawned by a Controls tab card of the
    /// Controls tab. Shares the exact geometry used in NotchPanelView so the
    /// hit-test lines up with what the user sees.
    private func popupZone(for popup: CenterPopup, screen: NSScreen) -> NSRect {
        let frame = screen.frame
        let ew = NotchDimensions.expandedWidth
        let panelLeft = frame.midX - ew / 2

        // Card row geometry must stay in sync with NotchPanelView.popupOffsetX.
        let innerLeft: CGFloat = panelLeft + 14
        let cardSpacing: CGFloat = 8
        let innerWidth = ew - 28
        let cardCount = NotchDimensions.centerStatusCardCount
        let totalSpacing = cardSpacing * (cardCount - 1)
        let cardWidth = (innerWidth - totalSpacing) / cardCount
        let cardCenterX =
            innerLeft + cardWidth / 2 +
            CGFloat(popup.cardIndex) * (cardWidth + cardSpacing)

        let pw = popup.popupWidth
        let ph = popup.popupHeight
        let gap = NotchDimensions.centerPopupGap

        // Clamp into the window's horizontal bounds so nothing renders outside.
        let windowLeft  = frame.midX - NotchDimensions.windowWidth / 2
        let windowRight = frame.midX + NotchDimensions.windowWidth / 2
        var x = cardCenterX - pw / 2
        x = min(max(x, windowLeft + 8), windowRight - pw - 8)

        let y = expandedZone.minY - ph - gap
        return NSRect(x: x, y: y, width: pw, height: ph)
    }

    private var activeCenterPopupZone: NSRect? {
        guard
            let popup = AppState.shared.quickSettingsVM.activeCenterPopup,
            let screen = currentScreen
        else { return nil }
        return popupZone(for: popup, screen: screen)
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

        if suppressOutsideClickHandling {
            return
        }

        guard isExpanded else {
            return
        }

        if event.type == .leftMouseDown && clickZone.contains(loc) {
            collapse()
            return
        }

        let insidePanel = expandedZone.insetBy(dx: -8, dy: -8).contains(loc)
        let insidePopup = activeCenterPopupZone?.insetBy(dx: -8, dy: -8).contains(loc) ?? false

        if !insidePanel && !insidePopup {
            // Clicked outside both the panel and (if open) the active center popup — dismiss.
            AppState.shared.quickSettingsVM.closeCenterPopup()
            collapse()
        } else if !insidePanel && insidePopup {
            // Click was inside the popup; keep panel open.
            return
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

    private func updateEnvironmentState(hideCollapsedImmediately: Bool = false) {
        guard let screen = currentScreen else { return }

        isFullscreenTriggerDisabled = detectFullscreenWindow(on: screen)

        if isFullscreenTriggerDisabled && isExpanded {
            collapse()
            return
        }

        refreshWindowVisibility(
            hideCollapsedImmediately: hideCollapsedImmediately || (isFullscreenTriggerDisabled && !isExpanded)
        )
    }

    private func handleActiveSpaceDidChange() {
        AppState.shared.launcherVM.reloadFromStorageIfChanged()

        if let screen = screenContaining(point: NSEvent.mouseLocation) ?? currentScreen ?? defaultScreen {
            moveWindows(to: screen, hideCollapsedImmediately: true)
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

    private func detectFullscreenWindow(on screen: NSScreen) -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return false
        }

        guard let infoList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return false
        }

        let screenFrame = screen.frame
        let tolerance: CGFloat = 6

        for info in infoList {
            let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t ?? 0
            let layer = info[kCGWindowLayer as String] as? Int ?? 0
            let alpha = info[kCGWindowAlpha as String] as? Double ?? 1

            guard ownerPID == app.processIdentifier, layer == 0, alpha > 0 else {
                continue
            }

            guard
                let boundsInfo = info[kCGWindowBounds as String] as? NSDictionary,
                let bounds = CGRect(dictionaryRepresentation: boundsInfo)
            else {
                continue
            }

            let fillsScreen =
                abs(bounds.minX - screenFrame.minX) <= tolerance &&
                abs(bounds.minY - screenFrame.minY) <= tolerance &&
                abs(bounds.width - screenFrame.width) <= tolerance &&
                abs(bounds.height - screenFrame.height) <= tolerance

            if fillsScreen {
                return true
            }
        }

        return false
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

    private func moveWindows(to screen: NSScreen, hideCollapsedImmediately: Bool) {
        preferredScreenID = displayID(for: screen)
        NotchDimensions.calibrate(from: screen)
        rebuildZones(screen: screen)

        if let panelWindow {
            panelWindow.setFrame(NotchPanelWindow.frame(for: screen), display: true)
        }

        triggerWindow?.setFrame(clickZone, display: true)
        updateEnvironmentState(hideCollapsedImmediately: hideCollapsedImmediately)
    }

    private func refreshWindowVisibility(hideCollapsedImmediately: Bool = false) {
        visibilityWorkItem?.cancel()
        visibilityWorkItem = nil

        guard let panelWindow, let triggerWindow else { return }

        panelWindow.ignoresMouseEvents = !isExpanded

        if isExpanded {
            panelWindow.orderFrontRegardless()
            triggerWindow.orderOut(nil)
            return
        }

        if isFullscreenTriggerDisabled {
            triggerWindow.orderOut(nil)

            if hideCollapsedImmediately {
                panelWindow.orderOut(nil)
                return
            }

            let workItem = DispatchWorkItem { [weak self] in
                guard let self, !self.isExpanded, self.isFullscreenTriggerDisabled else { return }
                self.panelWindow?.orderOut(nil)
            }
            visibilityWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: workItem)
        } else {
            panelWindow.orderFrontRegardless()
            triggerWindow.setFrame(clickZone, display: true)
            triggerWindow.orderFrontRegardless()
        }
    }

    // MARK: Expand / Collapse

    private func expand() {
        guard !isExpanded else { return }

        if isFullscreenTriggerDisabled {
            return
        }

        visibilityWorkItem?.cancel()
        visibilityWorkItem = nil

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
            refreshWindowVisibility(hideCollapsedImmediately: true)
            return
        }

        AppState.shared.quickSettingsVM.closeCenterPopup()
        AppState.shared.stopPolling()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
            isExpanded = false
        }

        refreshWindowVisibility()
    }

    // MARK: Screen Change

    @objc private func screensChanged() {
        guard let screen = currentScreen ?? defaultScreen else { return }
        moveWindows(to: screen, hideCollapsedImmediately: true)
    }
}
