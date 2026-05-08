import AppKit
import Combine

class LauncherViewModel: ObservableObject {
    @Published var apps: [AppItem] = []
    static let maxPinnedApps = 15

    private static let localChangeNotification = Notification.Name("NotchClickLauncherAppsDidChange")
    private static let distributedChangeNotification = Notification.Name("com.notchclick.app.launcherAppsDidChange")

    private let storageKey = "nd_launcher_apps"
    private var localObservers: [NSObjectProtocol] = []
    private var distributedObservers: [NSObjectProtocol] = []

    init() {
        load()
        startObservingLauncherChanges()
    }

    deinit {
        for observer in localObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        for observer in distributedObservers {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }

    // MARK: Persistence

    func load() {
        apps = storedApps()
        if UserDefaults.standard.data(forKey: storageKey) == nil {
            save(notify: false)
        }
    }

    func reloadFromStorageIfChanged() {
        let latest = storedApps()
        guard latest != apps else { return }
        apps = latest
    }

    func save(notify: Bool = true) {
        if let data = try? JSONEncoder().encode(apps) {
            UserDefaults.standard.set(data, forKey: storageKey)
            UserDefaults.standard.synchronize()

            if notify {
                notifyLauncherAppsChanged()
            }
        }
    }

    // MARK: Actions

    func launch(_ item: AppItem) {
        guard FileManager.default.fileExists(atPath: item.bundleURL.path) else {
            load()
            return
        }

        NSWorkspace.shared.openApplication(
            at: item.bundleURL,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }

    func add(_ item: AppItem) {
        reloadFromStorageIfChanged()
        guard apps.count < Self.maxPinnedApps else { return }

        let normalized = AppItem(name: item.name, bundleURL: item.bundleURL)
        guard !apps.contains(where: { $0.id == normalized.id }) else { return }
        apps.append(normalized)
        save()
    }

    func remove(at offsets: IndexSet) {
        reloadFromStorageIfChanged()
        apps.remove(atOffsets: offsets)
        save()
    }

    func move(draggedID: String, over targetID: String) {
        guard draggedID != targetID,
              let sourceIndex = apps.firstIndex(where: { $0.id == draggedID }),
              let targetIndex = apps.firstIndex(where: { $0.id == targetID }) else {
            return
        }

        let destination = targetIndex > sourceIndex ? targetIndex + 1 : targetIndex
        apps.move(fromOffsets: IndexSet(integer: sourceIndex), toOffset: destination)
        save()
    }

    func moveToEnd(draggedID: String) {
        guard let sourceIndex = apps.firstIndex(where: { $0.id == draggedID }),
              sourceIndex < apps.index(before: apps.endIndex) else {
            return
        }

        apps.move(fromOffsets: IndexSet(integer: sourceIndex), toOffset: apps.endIndex)
        save()
    }

    // MARK: Search installed apps

    func installedApps(matching query: String) -> [AppItem] {
        let dirs = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications")
        ]

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var seenIDs = Set<String>()
        var result: [AppItem] = []

        for dir in dirs {
            guard let enumerator = FileManager.default.enumerator(
                at: dir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for case let url as URL in enumerator where url.pathExtension.lowercased() == "app" {
                let item = AppItem(name: appName(for: url), bundleURL: url)
                guard seenIDs.insert(item.id).inserted else { continue }
                guard trimmedQuery.isEmpty || item.name.localizedStandardContains(trimmedQuery) else { continue }
                result.append(item)
            }
        }

        return result.sorted { $0.name < $1.name }
    }

    private func storedApps() -> [AppItem] {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([AppItem].self, from: data) {
            let sanitized = sanitizedApps(saved)
            return Array(sanitized.prefix(Self.maxPinnedApps))
        }

        return Array(AppItem.defaults.prefix(8))
    }

    private func sanitizedApps(_ items: [AppItem]) -> [AppItem] {
        var seenIDs = Set<String>()

        return items.compactMap { item in
            let normalized = AppItem(name: item.name, bundleURL: item.bundleURL)
            guard FileManager.default.fileExists(atPath: normalized.bundleURL.path) else { return nil }
            guard seenIDs.insert(normalized.id).inserted else { return nil }
            return normalized
        }
        .prefix(Self.maxPinnedApps)
        .map { $0 }
    }

    private func startObservingLauncherChanges() {
        localObservers.append(
            NotificationCenter.default.addObserver(
                forName: Self.localChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reloadFromStorageIfChanged()
            }
        )

        localObservers.append(
            NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: UserDefaults.standard,
                queue: .main
            ) { [weak self] _ in
                self?.reloadFromStorageIfChanged()
            }
        )

        distributedObservers.append(
            DistributedNotificationCenter.default().addObserver(
                forName: Self.distributedChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reloadFromStorageIfChanged()
            }
        )
    }

    private func notifyLauncherAppsChanged() {
        NotificationCenter.default.post(name: Self.localChangeNotification, object: nil)
        DistributedNotificationCenter.default().postNotificationName(
            Self.distributedChangeNotification,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    private func appName(for url: URL) -> String {
        let displayName = FileManager.default.displayName(atPath: url.path)
        guard !displayName.isEmpty else {
            return url.deletingPathExtension().lastPathComponent
        }

        return (displayName as NSString).deletingPathExtension
    }
}
