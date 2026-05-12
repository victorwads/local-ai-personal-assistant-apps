import Foundation

enum DebugTreeFavoritesStore {
    private static let storageKey = "debugTreeFavoritesV1"

    static func load() -> [String: [Int]] {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: storageKey) {
            do {
                return try JSONDecoder().decode([String: [Int]].self, from: data)
            } catch {
                return [:]
            }
        }

        // Back-compat: older versions stored JSON as a String via AppStorage.
        if let legacyString = defaults.string(forKey: storageKey) {
            let data = Data(legacyString.utf8)
            if let decoded = try? JSONDecoder().decode([String: [Int]].self, from: data) {
                defaults.set(data, forKey: storageKey)
                defaults.synchronize()
                return decoded
            }
        }

        return [:]
    }

    static func save(_ favorites: [String: [Int]]) {
        let defaults = UserDefaults.standard
        do {
            let data = try JSONEncoder().encode(favorites)
            defaults.set(data, forKey: storageKey)
            defaults.synchronize()
        } catch {
            // ignore
        }
    }
}
