import Foundation

@MainActor
final class DebugTreeFavoritesRepository {
    static let shared = DebugTreeFavoritesRepository()

    private let settingsService: FirestoreSettingsService
    private let storageKey = "debugTreeFavoritesV1"

    init(settingsService: FirestoreSettingsService = FirestoreSettingsService(profileID: AppProfile.default.id)) {
        self.settingsService = settingsService
    }

    func load() -> [String: [Int]] {
        guard let data = settingsService.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: [Int]].self, from: data) else {
            return [:]
        }
        return decoded
    }

    func save(_ favorites: [String: [Int]]) {
        guard let data = try? JSONEncoder().encode(favorites) else {
            return
        }
        Task { @MainActor in
            await settingsService.set(data, forKey: storageKey)
        }
    }
}
