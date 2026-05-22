import Foundation

@MainActor
final class WhatsAppWebSettingsRepository {
    static let shared = WhatsAppWebSettingsRepository()

    private let settingsService: FirestoreSettingsService
    private let userAgentKey = "whatsAppWeb.customUserAgent"
    private let inspectableKey = "whatsAppWeb.isInspectable"
    private let messageSettleDelayKey = "whatsAppWeb.messageSettleDelayMilliseconds"
    private let pageZoomKey = "whatsAppWeb.pageZoom"

    init(settingsService: FirestoreSettingsService = FirestoreSettingsService(profileID: AppProfile.default.id)) {
        self.settingsService = settingsService
    }

    func loadCustomUserAgent(defaultValue: String) -> String {
        let storedValue = settingsService.string(forKey: userAgentKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let storedValue, !storedValue.isEmpty else {
            return defaultValue
        }
        return storedValue
    }

    func saveCustomUserAgent(_ value: String) {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        Task { @MainActor in
            await settingsService.set(trimmedValue, forKey: userAgentKey)
        }
    }

    func loadInspectable(defaultValue: Bool) -> Bool {
        settingsService.value(forKey: inspectableKey) as? Bool ?? defaultValue
    }

    func saveInspectable(_ value: Bool) {
        Task { @MainActor in
            await settingsService.set(value, forKey: inspectableKey)
        }
    }

    func loadMessageSettleDelay(defaultValue: Double) -> Double {
        let value = settingsService.double(forKey: messageSettleDelayKey, default: defaultValue)
        return value > 0 ? value : defaultValue
    }

    func saveMessageSettleDelay(_ value: Double) {
        Task { @MainActor in
            await settingsService.set(value, forKey: messageSettleDelayKey)
        }
    }

    func loadPageZoom(defaultValue: Double) -> Double {
        let value = settingsService.double(forKey: pageZoomKey, default: defaultValue)
        return value > 0 ? value : defaultValue
    }

    func savePageZoom(_ value: Double) {
        Task { @MainActor in
            await settingsService.set(value, forKey: pageZoomKey)
        }
    }
}
