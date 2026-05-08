import AppKit
import Foundation

struct AppItem: Identifiable, Codable, Hashable {
    var name: String
    var bundleURL: URL

    init(name: String, bundleURL: URL) {
        let normalizedURL = bundleURL.standardizedFileURL.resolvingSymlinksInPath()
        self.name = name.isEmpty ? normalizedURL.deletingPathExtension().lastPathComponent : name
        self.bundleURL = normalizedURL
    }

    var id: String {
        bundleURL.path
    }

    var icon: NSImage {
        AppIconCache.icon(for: bundleURL)
    }
}

private enum AppIconCache {
    private static let cache = NSCache<NSString, NSImage>()

    static func icon(for url: URL) -> NSImage {
        let key = url.path as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let image = NSWorkspace.shared.icon(forFile: url.path)
        cache.setObject(image, forKey: key)
        return image
    }
}

// MARK: - Default Apps

extension AppItem {
    static var defaults: [AppItem] {
        let names = ["Safari", "Mail", "Notes", "Music", "Messages",
                     "Calendar", "Terminal", "Xcode", "Finder"]
        return names.compactMap { name in
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID(for: name))
                       ?? findByName(name) else { return nil }
            return AppItem(name: name, bundleURL: url)
        }
    }

    private static func bundleID(for name: String) -> String {
        let map: [String: String] = [
            "Safari":    "com.apple.Safari",
            "Mail":      "com.apple.mail",
            "Notes":     "com.apple.Notes",
            "Music":     "com.apple.Music",
            "Messages":  "com.apple.MobileSMS",
            "Calendar":  "com.apple.iCal",
            "Terminal":  "com.apple.Terminal",
            "Xcode":     "com.apple.dt.Xcode",
            "Finder":    "com.apple.finder"
        ]
        return map[name] ?? ""
    }

    private static func findByName(_ name: String) -> URL? {
        let paths = [
            "/Applications/\(name).app",
            "/System/Applications/\(name).app",
            "/System/Applications/Utilities/\(name).app"
        ]
        return paths.first(where: { FileManager.default.fileExists(atPath: $0) })
                    .map { URL(fileURLWithPath: $0) }
    }
}
