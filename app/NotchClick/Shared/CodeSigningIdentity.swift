import Foundation
import Security

enum CodeSigningIdentity {
    static func teamIdentifierForCurrentProcess() -> String? {
        teamIdentifier(forExecutableAt: Bundle.main.executableURL ?? URL(fileURLWithPath: CommandLine.arguments[0]))
    }

    static func teamIdentifier(forExecutableAt executableURL: URL?) -> String? {
        guard let executableURL else { return nil }

        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(executableURL as CFURL, SecCSFlags(), &staticCode) == errSecSuccess,
              let staticCode else {
            return nil
        }

        var signingInfo: CFDictionary?
        guard SecCodeCopySigningInformation(
            staticCode,
            SecCSFlags(rawValue: kSecCSSigningInformation),
            &signingInfo
        ) == errSecSuccess,
        let signingInfo = signingInfo as? [String: Any] else {
            return nil
        }

        return signingInfo[kSecCodeInfoTeamIdentifier as String] as? String
    }

    static func requirement(bundleIdentifier: String, teamIdentifier: String) -> String {
        "anchor apple generic and identifier \"\(bundleIdentifier)\" and certificate leaf[subject.OU] = \"\(teamIdentifier)\""
    }
}
