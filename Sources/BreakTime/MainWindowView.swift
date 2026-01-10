import SwiftUI

struct MainWindowView: View {
    @Bindable var engine: BreakTimeEngine
    @Bindable var permissions: PermissionsManager

    var body: some View {
        Group {
            if permissions.accessibilityStatus != .granted {
                OnboardingView(permissions: permissions)
            } else {
                TabView {
                    DashboardView(engine: engine)
                        .tabItem { Label("Dashboard", systemImage: "timer") }
                    SettingsView(engine: engine)
                        .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
                }
            }
        }
        .frame(minWidth: 560, maxWidth: 760, minHeight: 420, maxHeight: 600)
        .background(
            WindowSizingView(
                minSize: CGSize(width: 560, height: 420),
                maxSize: CGSize(width: 760, height: 600)
            )
        )
        .task {
            permissions.refresh()
            engine.startIfNeeded()
        }
    }
}
