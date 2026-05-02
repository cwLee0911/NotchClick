import Foundation

enum LowPowerModeHelperConstants {
    static let daemonPlistName = "com.notchclick.app.lowpowerd.plist"
    static let daemonMachServiceName = "com.notchclick.app.lowpowerd"
    static let helperExecutableName = "NotchClickLowPowerHelper"
    static let helperBundleIdentifier = "com.notchclick.app.lowpowerhelper"
    static let clientBundleIdentifier = "com.notchclick.app"
}

@objc protocol LowPowerModeHelperXPCProtocol {
    func setLowPowerModeEnabled(_ enabled: Bool, withReply reply: @escaping (Bool, String?) -> Void)
}
