import AppKit

@MainActor
final class SystemEventMonitor {
    private var observers: [NSObjectProtocol] = []
    private let onSuspend: @Sendable () -> Void
    private let onResume: @Sendable () -> Void
    private let onLock: @Sendable () -> Void
    private let onUnlock: @Sendable () -> Void

    init(
        onSuspend: @escaping @Sendable () -> Void,
        onResume: @escaping @Sendable () -> Void,
        onLock: @escaping @Sendable () -> Void,
        onUnlock: @escaping @Sendable () -> Void
    ) {
        self.onSuspend = onSuspend
        self.onResume = onResume
        self.onLock = onLock
        self.onUnlock = onUnlock
    }

    func start() {
        let center = NSWorkspace.shared.notificationCenter
        let onSuspend = self.onSuspend
        let onResume = self.onResume
        let onLock = self.onLock
        let onUnlock = self.onUnlock

        observers.append(center.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { _ in
            onSuspend()
        })
        observers.append(center.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            onResume()
        })
        observers.append(center.addObserver(
            forName: NSWorkspace.sessionDidResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            onLock()
        })
        observers.append(center.addObserver(
            forName: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            onUnlock()
        })
    }

    func stop() {
        let center = NSWorkspace.shared.notificationCenter
        for observer in observers {
            center.removeObserver(observer)
        }
        observers.removeAll()
    }
}
