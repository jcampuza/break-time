import AppKit

@MainActor
final class WorkspaceProcessMonitor {
    private let watchedBundleIds: Set<String>
    private var runningBundleIds = Set<String>()
    private var runningNames: [String: String] = [:]
    private var observers: [NSObjectProtocol] = []
    private var onChange: (([String]) -> Void)?
    private var lastEmitted: [String] = []

    init(watchedBundleIds: [String]) {
        self.watchedBundleIds = Set(watchedBundleIds)
    }

    func start(onChange: @escaping ([String]) -> Void) {
        self.onChange = onChange
        refreshRunningApps()

        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleId = app.bundleIdentifier
            else {
                return
            }
            let name = app.localizedName
            Task { @MainActor in
                self?.handleLaunch(bundleId: bundleId, name: name)
            }
        })
        observers.append(center.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleId = app.bundleIdentifier
            else {
                return
            }
            Task { @MainActor in
                self?.handleTerminate(bundleId: bundleId)
            }
        })
    }

    func stop() {
        let center = NSWorkspace.shared.notificationCenter
        for observer in observers {
            center.removeObserver(observer)
        }
        observers.removeAll()
        onChange = nil
        runningBundleIds.removeAll()
        runningNames.removeAll()
        lastEmitted.removeAll()
    }

    private func refreshRunningApps() {
        let running = NSWorkspace.shared.runningApplications
        var bundleIds = Set<String>()
        var names: [String: String] = [:]
        for app in running {
            guard let bundleId = app.bundleIdentifier else { continue }
            bundleIds.insert(bundleId)
            if let name = app.localizedName {
                names[bundleId] = name
            }
        }
        runningBundleIds = bundleIds
        runningNames = names
        emitIfNeeded()
    }

    private func handleLaunch(bundleId: String, name: String?) {
        runningBundleIds.insert(bundleId)
        if let name {
            runningNames[bundleId] = name
        }
        emitIfNeeded()
    }

    private func handleTerminate(bundleId: String) {
        runningBundleIds.remove(bundleId)
        runningNames.removeValue(forKey: bundleId)
        emitIfNeeded()
    }

    private func emitIfNeeded() {
        let matchedNames = watchedBundleIds.compactMap { bundleId -> String? in
            guard runningBundleIds.contains(bundleId) else { return nil }
            return runningNames[bundleId] ?? bundleId
        }.sorted()

        if matchedNames != lastEmitted {
            lastEmitted = matchedNames
            onChange?(matchedNames)
        }
    }
}
