import Foundation
import IOKit.ps
import Darwin

// MARK: - System Stats Model

struct SystemStats {
    var cpuUsage:     Double  // 0–100 %
    var memUsedGB:    Double
    var memTotalGB:   Double
    var batteryLevel: Int     // 0–100
    var isCharging:   Bool
    var hasBattery:   Bool
    var storageUsedGB:  Double
    var storageTotalGB: Double
    var isLowPowerMode: Bool

    var memUsagePercent: Double {
        guard memTotalGB > 0 else { return 0 }
        return memUsedGB / memTotalGB * 100
    }

    var storagePercent: Double {
        guard storageTotalGB > 0 else { return 0 }
        return storageUsedGB / storageTotalGB * 100
    }
}

// MARK: - Monitor

class SystemMonitor: ObservableObject {
    @Published var stats = SystemStats(
        cpuUsage: 0, memUsedGB: 0, memTotalGB: 0,
        batteryLevel: 0, isCharging: false, hasBattery: false,
        storageUsedGB: 0, storageTotalGB: 0, isLowPowerMode: false
    )
    @Published var lowPowerModeStatusMessage: String?
    @Published var isTogglingLowPowerMode = false
    @Published private(set) var hasPersistentLowPowerModeAccess = false

    private var timer: Timer?
    private var prevCPUInfo: processor_info_array_t?
    private var prevCPUInfoCount: mach_msg_type_number_t = 0
    private var lastCPUUsage = 0.0
    private let updateLock = NSLock()
    private var updateInFlight = false
    private var skippedLowPowerModeSetupThisSession = false
    private let privilegedHelper = LowPowerModePrivilegedHelper()
    private let pollingQueue = DispatchQueue(
        label: "com.notchclick.system-monitor",
        qos: .utility
    )

    init() {
        refreshLowPowerModeAccessStatus()
    }

    deinit {
        releasePreviousCPUInfo()
    }

    func startPolling() {
        timer?.invalidate()
        refreshLowPowerModeAccessStatus()
        scheduleUpdate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.scheduleUpdate()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
        pollingQueue.sync {
            releasePreviousCPUInfo()
            lastCPUUsage = 0
        }
        updateLock.lock()
        updateInFlight = false
        updateLock.unlock()
    }

    private func scheduleUpdate() {
        updateLock.lock()
        guard !updateInFlight else {
            updateLock.unlock()
            return
        }
        updateInFlight = true
        updateLock.unlock()

        pollingQueue.async { [weak self] in
            self?.update()
        }
    }

    private func update() {
        let cpu   = cpuUsage()
        let mem   = memoryInfo()
        let bat   = batteryInfo()
        let stor  = storageInfo()
        let lpm   = lowPowerModeEnabled()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.stats = SystemStats(
                cpuUsage:       cpu,
                memUsedGB:      mem.used,
                memTotalGB:     mem.total,
                batteryLevel:   bat.level,
                isCharging:     bat.isCharging,
                hasBattery:     bat.hasBattery,
                storageUsedGB:  stor.used,
                storageTotalGB: stor.total,
                isLowPowerMode: lpm
            )

            self.updateLock.lock()
            self.updateInFlight = false
            self.updateLock.unlock()
        }
    }

    // MARK: Public — Low Power Mode toggle

    func toggleLowPowerMode() {
        guard stats.hasBattery, !isTogglingLowPowerMode else { return }
        refreshLowPowerModeAccessStatus()

        let shouldEnable = !stats.isLowPowerMode
        let target = shouldEnable ? 1 : 0

        lowPowerModeStatusMessage = nil
        isTogglingLowPowerMode = true

        pollingQueue.async { [weak self] in
            guard let self else { return }

            var result: ShellCommandResult?

            switch self.privilegedHelper.toggle(enabled: shouldEnable) {
            case .success:
                self.skippedLowPowerModeSetupThisSession = false
            case .requiresApproval:
                DispatchQueue.main.async { [weak self] in
                    self?.isTogglingLowPowerMode = false
                    self?.lowPowerModeStatusMessage = L10n.lowPowerApprovalMessage(UserPreferences.shared.language)
                }
                self.refreshLowPowerModeAccessStatus()
                return
            case .unavailableInThisBuild:
                if !self.hasSudoersRuleInstalled && self.skippedLowPowerModeSetupThisSession {
                    DispatchQueue.main.async { [weak self] in
                        self?.isTogglingLowPowerMode = false
                        self?.lowPowerModeStatusMessage = L10n.lowPowerSetupNeededMessage(UserPreferences.shared.language)
                    }
                    return
                }

                result = self.toggleLowPowerModeViaSudoers(target: target)
            case .failure(let message):
                let effectiveState = self.lowPowerModeEnabled()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.stats.isLowPowerMode = effectiveState
                    self.lowPowerModeStatusMessage = message
                    self.isTogglingLowPowerMode = false
                }
                self.refreshLowPowerModeAccessStatus()
                self.scheduleUpdate()
                return
            }

            if let result, self.userCancelledAdminPrompt(result) {
                self.refreshLowPowerModeAccessStatus()
                self.scheduleUpdate()
                return
            }

            Thread.sleep(forTimeInterval: 0.35)

            let effectiveState = self.lowPowerModeEnabled()
            let statusMessage: String?

            if let result, result.exitCode != 0 {
                statusMessage = self.lowPowerModeFailureMessage(
                    shouldEnable: shouldEnable,
                    output: result.output
                )
            } else if effectiveState != shouldEnable {
                statusMessage = L10n.lowPowerApplyFailedMessage(UserPreferences.shared.language)
            } else {
                statusMessage = nil
            }

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.stats.isLowPowerMode = effectiveState
                self.lowPowerModeStatusMessage = statusMessage
                self.isTogglingLowPowerMode = false
            }

            self.refreshLowPowerModeAccessStatus()
            self.scheduleUpdate()
        }
    }

    // MARK: Sudoers installation (one-time setup)

    private var sudoersRulePath: String {
        "/etc/sudoers.d/notchclick-pmset"
    }

    private var hasSudoersRuleInstalled: Bool {
        FileManager.default.fileExists(atPath: sudoersRulePath)
    }

    /// Passwordless pmset invocation — succeeds only if the sudoers rule is installed.
    private func runPmsetPasswordless(target: Int) -> ShellCommandResult {
        shellResult("/usr/bin/sudo -n /usr/bin/pmset -a lowpowermode \(target)")
    }

    private func toggleLowPowerModeViaSudoers(target: Int) -> ShellCommandResult {
        var result = runPmsetPasswordless(target: target)

        if result.exitCode != 0 {
            let installResult = installSudoersRuleIfNeeded()

            if userCancelledAdminPrompt(installResult) {
                DispatchQueue.main.async { [weak self] in
                    self?.skippedLowPowerModeSetupThisSession = true
                    self?.isTogglingLowPowerMode = false
                    self?.lowPowerModeStatusMessage = L10n.lowPowerCancelledMessage(UserPreferences.shared.language)
                }
                return installResult
            }

            if installResult.exitCode == 0 {
                DispatchQueue.main.async { [weak self] in
                    self?.skippedLowPowerModeSetupThisSession = false
                }
                refreshLowPowerModeAccessStatus()
                result = runPmsetPasswordless(target: target)
            } else {
                result = installResult
            }
        }

        return result
    }

    /// Installs a narrowly-scoped sudoers rule that grants the current user
    /// passwordless access to `pmset -a lowpowermode 0|1` — and nothing else.
    /// Prompts for the admin password exactly once per machine.
    private func installSudoersRuleIfNeeded() -> ShellCommandResult {
        if FileManager.default.fileExists(atPath: sudoersRulePath) {
            return ShellCommandResult(output: "", exitCode: 0)
        }

        let username = NSUserName()
        // Narrow allow-list: only these two exact commands, nothing else.
        let content = """
        # Installed by NotchClick — grants passwordless Low Power Mode toggling.
        # Remove this file (sudo rm /etc/sudoers.d/notchclick-pmset) to revoke.
        \(username) ALL=(root) NOPASSWD: /usr/bin/pmset -a lowpowermode 0
        \(username) ALL=(root) NOPASSWD: /usr/bin/pmset -a lowpowermode 1
        """

        let tmpPath = (NSTemporaryDirectory() as NSString)
            .appendingPathComponent("notchclick-pmset.sudoers")

        do {
            try content.write(toFile: tmpPath, atomically: true, encoding: .utf8)
        } catch {
            return ShellCommandResult(
                output: "Couldn't stage sudoers file: \(error.localizedDescription)",
                exitCode: -1
            )
        }

        // Validate with visudo, then atomically move into place with correct perms.
        let install = """
        /usr/sbin/visudo -cf '\(tmpPath)' && \
        /usr/sbin/chown root:wheel '\(tmpPath)' && \
        /bin/chmod 440 '\(tmpPath)' && \
        /bin/mv '\(tmpPath)' '\(sudoersRulePath)'
        """
        return runAsAdmin(install)
    }

    private func refreshLowPowerModeAccessStatus() {
        let isInstalled = privilegedHelper.hasPersistentAccess || hasSudoersRuleInstalled
        DispatchQueue.main.async { [weak self] in
            self?.hasPersistentLowPowerModeAccess = isInstalled
        }
    }

    // MARK: CPU

    private func cpuUsage() -> Double {
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0

        let err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO,
                                       &numCPUs, &cpuInfo, &numCpuInfo)
        guard err == KERN_SUCCESS, let cpuInfo else { return 0 }

        guard let previousInfo = prevCPUInfo, prevCPUInfoCount == numCpuInfo else {
            prevCPUInfo = cpuInfo
            prevCPUInfoCount = numCpuInfo
            return lastCPUUsage
        }

        let count = Int(numCPUs)
        guard count > 0 else { return lastCPUUsage }
        var totalUsage = 0.0

        for i in 0..<count {
            let current = cpuLoadSnapshot(from: cpuInfo, cpuIndex: i)
            let previous = cpuLoadSnapshot(from: previousInfo, cpuIndex: i)

            let userDelta = max(0, current.user - previous.user)
            let systemDelta = max(0, current.system - previous.system)
            let niceDelta = max(0, current.nice - previous.nice)
            let idleDelta = max(0, current.idle - previous.idle)

            let usedDelta = Double(userDelta + systemDelta + niceDelta)
            let totalDelta = usedDelta + Double(idleDelta)
            totalUsage += totalDelta > 0 ? usedDelta / totalDelta * 100 : 0
        }

        releasePreviousCPUInfo()
        prevCPUInfo = cpuInfo
        prevCPUInfoCount = numCpuInfo

        let usage = totalUsage / Double(count)
        lastCPUUsage = usage
        return usage
    }

    // MARK: Memory

    private func memoryInfo() -> (used: Double, total: Double) {
        var vmStats = vm_statistics64()
        var count   = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, 0) }

        let pageSize  = Double(vm_kernel_page_size)
        let usedPages = max(
            0,
            Double(vmStats.internal_page_count + vmStats.wire_count + vmStats.compressor_page_count)
                - Double(vmStats.purgeable_count)
        )
        let used      = usedPages * pageSize / 1_073_741_824
        let total     = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824
        return (used, total)
    }

    // MARK: Battery

    private func batteryInfo() -> (level: Int, isCharging: Bool, hasBattery: Bool) {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources  = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]

        for source in sources {
            guard let raw = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() else { continue }
            let dict = raw as NSDictionary

            let current  = dict[kIOPSCurrentCapacityKey] as? Int  ?? 0
            let maxCap   = dict[kIOPSMaxCapacityKey]     as? Int  ?? 100
            let charging = dict[kIOPSIsChargingKey]      as? Bool ?? false
            return (current * 100 / max(maxCap, 1), charging, true)
        }
        return (0, false, false)
    }

    // MARK: Storage

    private func storageInfo() -> (used: Double, total: Double) {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        guard let values = try? url.resourceValues(forKeys: [
            .volumeAvailableCapacityKey,
            .volumeTotalCapacityKey
        ]) else { return (0, 0) }

        let total = Double(values.volumeTotalCapacity ?? 0) / 1_073_741_824
        let free  = Double(values.volumeAvailableCapacity ?? 0) / 1_073_741_824
        return (total - free, total)
    }

    // MARK: Low Power Mode

    private func lowPowerModeEnabled() -> Bool {
        let output = shell("pmset -g | grep lowpowermode")
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        // line looks like "lowpowermode         1"
        return trimmed.components(separatedBy: .whitespaces).last == "1"
    }

    // MARK: Shell helper

    private struct ShellCommandResult {
        let output: String
        let exitCode: Int32
    }

    private func shellResult(_ cmd: String) -> ShellCommandResult {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", cmd]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
        } catch {
            return ShellCommandResult(output: error.localizedDescription, exitCode: -1)
        }

        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return ShellCommandResult(output: output, exitCode: task.terminationStatus)
    }

    private func shell(_ cmd: String) -> String {
        shellResult(cmd).output
    }

    /// Runs a shell command with admin privileges via AppleScript. macOS shows
    /// a system password prompt; the entered credential is cached for ~5 min
    /// so subsequent toggles in the same session don't re-prompt.
    private func runAsAdmin(_ cmd: String) -> ShellCommandResult {
        let escaped = cmd
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"\(escaped)\" with administrator privileges"

        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
        } catch {
            return ShellCommandResult(output: error.localizedDescription, exitCode: -1)
        }

        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return ShellCommandResult(output: output, exitCode: task.terminationStatus)
    }

    private func looksLikePermissionIssue(_ output: String) -> Bool {
        let lower = output.lowercased()
        return lower.contains("not permitted")
            || lower.contains("permission")
            || lower.contains("must be run as root")
            || lower.contains("requires root")
            || lower.contains("operation not permitted")
    }

    private func userCancelledAdminPrompt(_ result: ShellCommandResult) -> Bool {
        // osascript emits "User canceled." and exits 1 when the auth dialog is dismissed.
        result.exitCode != 0 && result.output.lowercased().contains("user canceled")
    }

    private func lowPowerModeFailureMessage(shouldEnable: Bool, output: String) -> String {
        let normalizedOutput = output.lowercased()
        let languageCode = UserPreferences.shared.language

        if !FileManager.default.fileExists(atPath: sudoersRulePath) {
            return L10n.lowPowerFailureMessage(
                shouldEnable: shouldEnable,
                reason: .setup,
                languageCode
            )
        }

        if normalizedOutput.contains("root") || normalizedOutput.contains("admin") {
            return L10n.lowPowerFailureMessage(
                shouldEnable: shouldEnable,
                reason: .admin,
                languageCode
            )
        }

        if normalizedOutput.contains("not permitted") || normalizedOutput.contains("permission") {
            return L10n.lowPowerFailureMessage(
                shouldEnable: shouldEnable,
                reason: .permission,
                languageCode
            )
        }

        return L10n.lowPowerFailureMessage(
            shouldEnable: shouldEnable,
            reason: .generic,
            languageCode
        )
    }
    private func cpuLoadSnapshot(from cpuInfo: processor_info_array_t, cpuIndex: Int) -> (user: UInt64, system: UInt64, nice: UInt64, idle: UInt64) {
        let base = Int(CPU_STATE_MAX) * cpuIndex
        return (
            user: UInt64(UInt32(bitPattern: cpuInfo[base + Int(CPU_STATE_USER)])),
            system: UInt64(UInt32(bitPattern: cpuInfo[base + Int(CPU_STATE_SYSTEM)])),
            nice: UInt64(UInt32(bitPattern: cpuInfo[base + Int(CPU_STATE_NICE)])),
            idle: UInt64(UInt32(bitPattern: cpuInfo[base + Int(CPU_STATE_IDLE)]))
        )
    }

    private func releasePreviousCPUInfo() {
        guard let prevCPUInfo else { return }
        vm_deallocate(
            mach_task_self_,
            vm_address_t(bitPattern: prevCPUInfo),
            vm_size_t(prevCPUInfoCount) * vm_size_t(MemoryLayout<integer_t>.size)
        )
        self.prevCPUInfo = nil
        prevCPUInfoCount = 0
    }
}
