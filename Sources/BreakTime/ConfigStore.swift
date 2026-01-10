import Foundation
import BreakTimeCore

struct ConfigStore {
    private let storageKey = "BreakTime.Config"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AntiRsiConfig? {
        guard let data = defaults.data(forKey: storageKey) else {
            return nil
        }
        return try? JSONDecoder().decode(AntiRsiConfig.self, from: data)
    }

    func save(_ config: AntiRsiConfig) {
        guard let data = try? JSONEncoder().encode(config) else {
            return
        }
        defaults.set(data, forKey: storageKey)
    }
}
