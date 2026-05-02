import Foundation
import ServiceManagement

enum LowPowerModeHelperToggleResult {
    case success
    case requiresApproval
    case unavailableInThisBuild
    case failure(String)
}

final class LowPowerModePrivilegedHelper {
    private enum PreparationResult {
        case ready
        case requiresApproval
        case unavailableInThisBuild
        case failure(String)
    }

    private let service = SMAppService.daemon(plistName: LowPowerModeHelperConstants.daemonPlistName)

    var hasPersistentAccess: Bool {
        service.status == .enabled
    }

    func toggle(enabled: Bool) -> LowPowerModeHelperToggleResult {
        switch ensureDaemonReady() {
        case .ready:
            return sendToggleRequest(enabled: enabled)
        case .requiresApproval:
            return .requiresApproval
        case .unavailableInThisBuild:
            return .unavailableInThisBuild
        case .failure(let message):
            return .failure(message)
        }
    }

    private func ensureDaemonReady() -> PreparationResult {
        switch service.status {
        case .enabled:
            return .ready
        case .requiresApproval:
            SMAppService.openSystemSettingsLoginItems()
            return .requiresApproval
        case .notRegistered:
            do {
                try service.register()
            } catch {
                return mapServiceError(error as NSError)
            }

            switch service.status {
            case .enabled:
                return .ready
            case .requiresApproval:
                SMAppService.openSystemSettingsLoginItems()
                return .requiresApproval
            case .notFound:
                return .unavailableInThisBuild
            case .notRegistered:
                return .failure("The Low Power helper didn't finish registering.")
            @unknown default:
                return .failure("The Low Power helper returned an unknown registration state.")
            }
        case .notFound:
            return .unavailableInThisBuild
        @unknown default:
            return .failure("The Low Power helper isn't available in this macOS build.")
        }
    }

    private func mapServiceError(_ error: NSError) -> PreparationResult {
        switch error.code {
        case kSMErrorAlreadyRegistered:
            return .ready
        case kSMErrorLaunchDeniedByUser:
            SMAppService.openSystemSettingsLoginItems()
            return .requiresApproval
        case kSMErrorInvalidSignature, kSMErrorToolNotValid, kSMErrorJobNotFound:
            return .unavailableInThisBuild
        default:
            break
        }

        return .failure(error.localizedDescription)
    }

    private func sendToggleRequest(enabled: Bool) -> LowPowerModeHelperToggleResult {
        let connection = NSXPCConnection(
            machServiceName: LowPowerModeHelperConstants.daemonMachServiceName,
            options: .privileged
        )
        connection.remoteObjectInterface = NSXPCInterface(with: LowPowerModeHelperXPCProtocol.self)

        guard let teamIdentifier = CodeSigningIdentity.teamIdentifierForCurrentProcess() else {
            connection.invalidate()
            return .failure("The Low Power helper could not verify this app's code signature.")
        }

        connection.setCodeSigningRequirement(
            CodeSigningIdentity.requirement(
                bundleIdentifier: LowPowerModeHelperConstants.helperBundleIdentifier,
                teamIdentifier: teamIdentifier
            )
        )

        var result: LowPowerModeHelperToggleResult = .failure("The Low Power helper didn't respond.")
        let semaphore = DispatchSemaphore(value: 0)

        let proxy = connection.remoteObjectProxyWithErrorHandler { error in
            result = .failure(error.localizedDescription)
            semaphore.signal()
        } as? LowPowerModeHelperXPCProtocol

        guard let proxy else {
            connection.invalidate()
            return .failure("The Low Power helper couldn't be reached.")
        }

        connection.activate()
        proxy.setLowPowerModeEnabled(enabled) { success, message in
            result = success ? .success : .failure(message ?? "Low Power Mode didn't change.")
            semaphore.signal()
        }

        if semaphore.wait(timeout: .now() + 5) == .timedOut {
            result = .failure("The Low Power helper timed out.")
        }

        connection.invalidate()
        return result
    }
}
