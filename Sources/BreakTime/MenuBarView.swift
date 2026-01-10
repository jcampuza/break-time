import SwiftUI
import AppKit

struct MenuBarView: View {
    @Bindable var engine: BreakTimeEngine
    @Bindable var permissions: PermissionsManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack {
            Button("Open BreakTime") {
                openMainWindow()
            }

            if permissions.accessibilityStatus != .granted {
                Divider()
                Button("Open Accessibility Settings") {
                    permissions.openAccessibilitySettings()
                }
                Button("Refresh Permissions") {
                    permissions.refresh()
                }
            }

            Divider()

            Button("Start Work Break") {
                engine.startWorkBreak()
            }
            Button("Micro Pause") {
                engine.startMiniBreak()
            }
            Button("Postpone Work Break") {
                engine.postponeWorkBreak()
            }
            Button(engine.isPaused ? "Resume Timers" : "Pause Timers") {
                engine.setUserPaused(!engine.isPaused)
            }
            Button("Reset Timers") {
                engine.resetTimings()
            }

            Divider()

            Button("Quit BreakTime") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.vertical, 6)
    }

    private func openMainWindow() {
        openWindow(id: "main")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
