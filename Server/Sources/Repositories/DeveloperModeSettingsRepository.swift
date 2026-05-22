import Foundation

@MainActor
final class DeveloperModeSettingsRepository {
    private let settingsService: FirestoreSettingsService
    private let storageKey = "developerModeEnabled.v1"

    init(settingsService: FirestoreSettingsService = FirestoreSettingsService(profileID: AppProfile.default.id)) {
        self.settingsService = settingsService
    }

    func load() -> Bool {
        settingsService.value(forKey: storageKey) as? Bool ?? false
    }

    func save(_ enabled: Bool) {
        Task { @MainActor in
            await settingsService.set(enabled, forKey: storageKey)
        }
    }
}
