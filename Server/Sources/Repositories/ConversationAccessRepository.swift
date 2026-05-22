import Foundation

@MainActor
final class ConversationAccessRepository {
    static let shared = ConversationAccessRepository()

    private let settingsService: FirestoreSettingsService

    private let conversationAccessModeDefaultsKey = "conversationAccessMode.v1"
    private let denyConversationNamesDefaultsKey = "denyConversationNames.v1"
    private let allowConversationNamesDefaultsKey = "allowConversationNames.v1"

    init(settingsService: FirestoreSettingsService = FirestoreSettingsService(profileID: AppProfile.default.id)) {
        self.settingsService = settingsService
    }

    func load() -> (mode: ConversationAccessMode, deny: [String], allow: [String]) {
        let mode: ConversationAccessMode = {
            if let raw = settingsService.string(forKey: conversationAccessModeDefaultsKey),
               let decoded = ConversationAccessMode(rawValue: raw) {
                return decoded
            }
            return .allowAllExceptDeny
        }()

        let deny: [String] = {
            if let deny = settingsService.value(forKey: denyConversationNamesDefaultsKey) as? [String] {
                return deny.sorted()
            }

            return []
        }()

        let allow = ((settingsService.value(forKey: allowConversationNamesDefaultsKey) as? [String]) ?? []).sorted()
        return (mode: mode, deny: deny, allow: allow)
    }

    func save(mode: ConversationAccessMode, deny: [String], allow: [String]) {
        Task { @MainActor in
            await settingsService.set(mode.rawValue, forKey: conversationAccessModeDefaultsKey)
            await settingsService.set(deny, forKey: denyConversationNamesDefaultsKey)
            await settingsService.set(allow, forKey: allowConversationNamesDefaultsKey)
        }
    }
}
