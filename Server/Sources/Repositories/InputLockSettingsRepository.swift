import Foundation

@MainActor
final class InputLockSettingsRepository {
    static let shared = InputLockSettingsRepository()

    private let settingsService: FirestoreSettingsService
    private let storageKey = "experimentalInputLockEnabled"

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
