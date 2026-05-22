import Foundation

@MainActor
final class ExperimentalSpeakSettingsRepository {
    static let shared = ExperimentalSpeakSettingsRepository()

    private let settingsService: FirestoreSettingsService
    private let storageKey = "experimentalSpeakApiEnabled"

    init(settingsService: FirestoreSettingsService = FirestoreSettingsService(profileID: AppProfile.default.id)) {
        self.settingsService = settingsService
    }

    func load(defaultValue: Bool = true) -> Bool {
        settingsService.value(forKey: storageKey) as? Bool ?? defaultValue
    }

    func save(_ enabled: Bool) {
        Task { @MainActor in
            await settingsService.set(enabled, forKey: storageKey)
        }
    }
}
