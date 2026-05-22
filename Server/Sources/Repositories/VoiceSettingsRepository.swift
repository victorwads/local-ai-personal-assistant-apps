import AVFoundation
import Foundation

@MainActor
final class VoiceSettingsRepository {
    static let shared = VoiceSettingsRepository()

    private let settingsService: FirestoreSettingsService

    private let speechVoiceIdentifierDefaultsKey = "speechVoiceIdentifier"
    private let speechLanguageDefaultsKey = "speechLanguage"
    private let speechRateDefaultsKey = "speechRate"
    private let recognitionLocaleIdentifierDefaultsKey = "recognitionLocaleIdentifier"

    init(settingsService: FirestoreSettingsService = FirestoreSettingsService(profileID: AppProfile.default.id)) {
        self.settingsService = settingsService
    }

    func load() -> (voiceIdentifier: String?, language: String, rate: Float, recognitionLocale: String) {
        let voiceIdentifier = settingsService.string(forKey: speechVoiceIdentifierDefaultsKey)
        let language = settingsService.string(forKey: speechLanguageDefaultsKey) ?? "pt-BR"
        let recognitionLocale = settingsService.string(forKey: recognitionLocaleIdentifierDefaultsKey) ?? "pt-BR"
        let rate = Float(settingsService.double(forKey: speechRateDefaultsKey, default: Double(AVSpeechUtteranceDefaultSpeechRate)))

        return (voiceIdentifier: voiceIdentifier, language: language, rate: rate, recognitionLocale: recognitionLocale)
    }

    func save(voiceIdentifier: String?, language: String, rate: Float, recognitionLocale: String) {
        Task { @MainActor in
            await settingsService.set(voiceIdentifier, forKey: speechVoiceIdentifierDefaultsKey)
            await settingsService.set(language, forKey: speechLanguageDefaultsKey)
            await settingsService.set(Double(rate), forKey: speechRateDefaultsKey)
            await settingsService.set(recognitionLocale, forKey: recognitionLocaleIdentifierDefaultsKey)
        }
    }
}
