import Dispatch
import Darwin
import Foundation

final class LowPowerModeHelperService: NSObject, LowPowerModeHelperXPCProtocol {
    func setLowPowerModeEnabled(_ enabled: Bool, withReply reply: @escaping (Bool, String?) -> Void) {
        let result = runPmset(enabled: enabled)
        reply(result.success, result.message)
    }

    private func runPmset(enabled: Bool) -> (success: Bool, message: String?) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["-a", "lowpowermode", enabled ? "1" : "0"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
        } catch {
            return (false, error.localizedDescription)
        }

        task.waitUntilExit()
        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if task.terminationStatus == 0 {
            return (true, nil)
        }

        return (false, output?.isEmpty == false ? output : "pmset exited with code \(task.terminationStatus).")
    }
}

final class LowPowerModeHelperDelegate: NSObject, NSXPCListenerDelegate {
    private let service = LowPowerModeHelperService()

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: LowPowerModeHelperXPCProtocol.self)
        newConnection.exportedObject = service
        newConnection.resume()
        return true
    }
}

let listener = NSXPCListener(machServiceName: LowPowerModeHelperConstants.daemonMachServiceName)

guard let teamIdentifier = CodeSigningIdentity.teamIdentifierForCurrentProcess() else {
    FileHandle.standardError.write(
        Data("NotchClickLowPowerHelper refused to start because its Team ID could not be verified.\n".utf8)
    )
    exit(EXIT_FAILURE)
}

listener.setConnectionCodeSigningRequirement(
    CodeSigningIdentity.requirement(
        bundleIdentifier: LowPowerModeHelperConstants.clientBundleIdentifier,
        teamIdentifier: teamIdentifier
    )
)

let delegate = LowPowerModeHelperDelegate()
listener.delegate = delegate
listener.activate()
dispatchMain()
