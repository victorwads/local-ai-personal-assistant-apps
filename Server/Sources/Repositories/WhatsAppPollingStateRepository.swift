import Foundation

@MainActor
final class WhatsAppPollingStateRepository {
    private enum Keys {
        static let pollingEnabled = "whatsApp.polling.enabled"
    }

    private let settingsService: FirestoreSettingsService

    init(settingsService: FirestoreSettingsService = FirestoreSettingsService(profileID: AppProfile.default.id)) {
        self.settingsService = settingsService
    }

    /// When unset, default to enabled so the app starts polling on first launch.
    func loadPollingEnabled(defaultValue: Bool = true) -> Bool {
        settingsService.value(forKey: Keys.pollingEnabled) as? Bool ?? defaultValue
    }

    func savePollingEnabled(_ enabled: Bool) {
        Task { @MainActor in
            await settingsService.set(enabled, forKey: Keys.pollingEnabled)
        }
    }
}
