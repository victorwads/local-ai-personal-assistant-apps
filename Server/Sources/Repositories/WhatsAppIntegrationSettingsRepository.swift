import Foundation

@MainActor
final class WhatsAppIntegrationSettingsRepository {
    static let shared = WhatsAppIntegrationSettingsRepository()

    private let settingsService: FirestoreSettingsService
    private let modeKey = "whatsApp.integrationMode"

    init(settingsService: FirestoreSettingsService = FirestoreSettingsService(profileID: AppProfile.default.id)) {
        self.settingsService = settingsService
    }

    func loadMode(defaultValue: WhatsAppIntegrationMode) -> WhatsAppIntegrationMode {
        let raw = settingsService.string(forKey: modeKey)
        return WhatsAppIntegrationMode(rawValue: raw ?? "") ?? defaultValue
    }

    func saveMode(_ mode: WhatsAppIntegrationMode) {
        Task { @MainActor in
            await settingsService.set(mode.rawValue, forKey: modeKey)
        }
    }
}
