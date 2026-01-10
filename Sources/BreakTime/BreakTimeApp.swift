import AppKit
import SwiftUI

@main
struct BreakTimeApp: App {
    @State private var engine = BreakTimeEngine()
    @State private var permissions = PermissionsManager()

    @MainActor
    init() {
        _ = NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        WindowGroup("BreakTime", id: "main") {
            MainWindowView(engine: engine, permissions: permissions)
        }
        .defaultSize(width: 680, height: 520)

        MenuBarExtra("BreakTime", systemImage: "hand.raised") {
            MenuBarView(engine: engine, permissions: permissions)
        }
    }
}
