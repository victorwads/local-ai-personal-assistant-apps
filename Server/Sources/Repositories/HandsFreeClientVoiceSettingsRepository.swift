import Foundation

@MainActor
final class HandsFreeClientVoiceSettingsRepository {
    static let shared = HandsFreeClientVoiceSettingsRepository()
    static let defaultDebounceSeconds = 2.5

    private let settingsService: FirestoreSettingsService
    private let enabledStorageKey = "handsFreeClientVoiceEnabled"
    private let debounceSecondsStorageKey = "handsFreeClientVoiceDebounceSeconds"

    init(settingsService: FirestoreSettingsService = FirestoreSettingsService(profileID: AppProfile.default.id)) {
        self.settingsService = settingsService
    }

    func load(defaultValue: Bool = true) -> Bool {
        settingsService.value(forKey: enabledStorageKey) as? Bool ?? defaultValue
    }

    func save(_ enabled: Bool) {
        Task { @MainActor in
            await settingsService.set(enabled, forKey: enabledStorageKey)
        }
    }

    func loadDebounceSeconds(defaultValue: Double = 2.5) -> Double {
        Self.clampDebounceSeconds(settingsService.double(forKey: debounceSecondsStorageKey, default: defaultValue))
    }

    func save(debounceSeconds: Double) {
        let clamped = Self.clampDebounceSeconds(debounceSeconds)
        Task { @MainActor in
            await settingsService.set(clamped, forKey: debounceSecondsStorageKey)
        }
    }

    private static func clampDebounceSeconds(_ value: Double) -> Double {
        max(0.5, min(value, 5.0))
    }
}
