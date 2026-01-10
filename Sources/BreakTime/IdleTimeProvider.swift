import Foundation
import IOKit

protocol IdleTimeProviding {
    func idleTimeSeconds() -> Double
}

struct SystemIdleTimeProvider: IdleTimeProviding {
    func idleTimeSeconds() -> Double {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))
        guard service != 0 else {
            return 0
        }
        defer { IOObjectRelease(service) }

        var properties: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0)
        guard result == KERN_SUCCESS,
              let dictionary = properties?.takeRetainedValue() as? [String: Any],
              let value = dictionary["HIDIdleTime"] as? NSNumber
        else {
            return 0
        }

        return value.doubleValue / 1_000_000_000
    }
}
