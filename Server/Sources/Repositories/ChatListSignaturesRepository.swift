import Foundation

@MainActor
final class ChatListSignaturesRepository {
    static let shared = ChatListSignaturesRepository()

    private let settingsService: FirestoreSettingsService
    private let storageKey = "chatListSignatures.v1"

    init(settingsService: FirestoreSettingsService = FirestoreSettingsService(profileID: AppProfile.default.id)) {
        self.settingsService = settingsService
    }

    func load() throws -> PersistedChatListSignatures? {
        guard let data = settingsService.data(forKey: storageKey) else {
            return nil
        }
        return try JSONDecoder().decode(PersistedChatListSignatures.self, from: data)
    }

    func save(_ payload: PersistedChatListSignatures) throws {
        let data = try JSONEncoder().encode(payload)
        Task { @MainActor in
            await settingsService.set(data, forKey: storageKey)
        }
    }
}
