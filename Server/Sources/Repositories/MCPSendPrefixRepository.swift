import Foundation

@MainActor
final class MCPSendPrefixRepository {
    static let shared = MCPSendPrefixRepository()

    private let settingsService: FirestoreSettingsService
    private let storageKey = "mcpSendMessagePrefix"
    private let assistantNameKey = "mcpSendMessageAssistantName"
    private let signatureKey = "mcpSendMessageSignature"

    init(settingsService: FirestoreSettingsService = FirestoreSettingsService(profileID: AppProfile.default.id)) {
        self.settingsService = settingsService
    }

    func load() -> (assistantName: String, signature: String) {
        let assistantName = settingsService.string(forKey: assistantNameKey)
        let signature = settingsService.string(forKey: signatureKey)
        return (
            assistantName: assistantName ?? "",
            signature: signature ?? ""
        )
    }

    func save(assistantName: String, signature: String) {
        Task { @MainActor in
            await settingsService.set(assistantName, forKey: assistantNameKey)
            await settingsService.set(signature, forKey: signatureKey)
            await settingsService.set(assistantName, forKey: storageKey)
        }
    }
}
