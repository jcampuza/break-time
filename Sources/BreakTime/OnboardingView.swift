import SwiftUI

struct OnboardingView: View {
    @Bindable var permissions: PermissionsManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Enable Accessibility Access")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("BreakTime needs Accessibility access to monitor input idle time accurately and to manage break overlays.")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Text("1. Open System Settings → Privacy & Security → Accessibility.")
                Text("2. Enable BreakTime in the list.")
                Text("3. Return here and BreakTime will detect it automatically.")
            }
            .font(.body)

            HStack(spacing: 12) {
                Button("Open Accessibility Settings") {
                    permissions.openAccessibilitySettings()
                }
                .buttonStyle(.borderedProminent)

                Button("Request Permission") {
                    permissions.requestAccessibility()
                }
                .buttonStyle(.bordered)

                Button("Refresh") {
                    permissions.refresh()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(32)
        .onAppear {
            permissions.refresh()
        }
        .onChange(of: scenePhase) { newPhase in
            guard newPhase == .active else {
                return
            }
            permissions.refresh()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard permissions.accessibilityStatus != .granted else {
                    continue
                }
                permissions.refresh()
            }
        }
    }
}
