import AppKit
import SwiftUI
import BreakTimeCore

@MainActor
final class OverlayManager {
    private unowned let engine: BreakTimeEngine
    private var windows: [OverlayPanel] = []
    private var delegates: [ObjectIdentifier: OverlayWindowDelegate] = [:]

    init(engine: BreakTimeEngine) {
        self.engine = engine
    }

    func handle(event: AntiRsiEvent, snapshot: AntiRsiSnapshot) {
        _ = snapshot
        switch event {
        case .miniBreakStart:
            ensureOverlayWindows(for: .mini)
        case .workBreakStart:
            ensureOverlayWindows(for: .work)
        case .breakEnd:
            hideOverlayWindows()
        case .breakUpdate:
            break
        case .statusUpdate, .paused, .resumed:
            break
        }
    }

    private func ensureOverlayWindows(for breakType: BreakType) {
        let screens = NSScreen.screens

        if windows.count == screens.count {
            for window in windows {
                window.setFrame(window.screen?.frame ?? window.frame, display: true)
                window.orderFrontRegardless()
            }
            return
        }

        hideOverlayWindows()

        windows = screens.map { screen in
            let panel = OverlayPanel(contentRect: screen.frame)
            panel.level = .screenSaver
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
            let delegate = OverlayWindowDelegate { [weak self] in
                self?.handleOverlayClose(for: breakType)
            }
            panel.delegate = delegate
            delegates[ObjectIdentifier(panel)] = delegate
            panel.contentView = NSHostingView(rootView: BreakOverlayView(engine: engine))
            panel.setFrame(screen.frame, display: true)
            panel.makeKeyAndOrderFront(nil)
            return panel
        }
    }

    private func handleOverlayClose(for breakType: BreakType) {
        let snapshot = engine.snapshot
        switch breakType {
        case .mini where snapshot.state == .inMini:
            engine.skipMiniBreak()
        case .work where snapshot.state == .inWork:
            engine.skipWorkBreak()
        default:
            break
        }
    }

    private func hideOverlayWindows() {
        for window in windows {
            window.delegate = nil
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()
        delegates.removeAll()
    }
}

final class OverlayPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isMovable = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        hasShadow = false
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}

final class OverlayWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
