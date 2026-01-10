import AppKit
@preconcurrency import ApplicationServices
import Observation

@MainActor
@Observable
final class PermissionsManager {
    enum Status: String {
        case unknown
        case granted
        case denied
    }

    var accessibilityStatus: Status = .unknown

    func refresh() {
        accessibilityStatus = AXIsProcessTrusted() ? .granted : .denied
    }

    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        refresh()
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
