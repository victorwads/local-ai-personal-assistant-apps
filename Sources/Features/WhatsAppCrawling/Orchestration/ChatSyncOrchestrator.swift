import Foundation

final class ChatSyncOrchestrator {
    private let integration: any WhatsAppCrawlingIntegration
    private let chatNormalizer: ChatNormalizer
    private let chatIdGenerator: ChatIdGenerator
    private let messageSyncOrchestrator: MessageSyncOrchestrator
    private let checkpointStore: any CrawlingCheckpointStore

    init(
        integration: any WhatsAppCrawlingIntegration,
        messageSyncOrchestrator: MessageSyncOrchestrator,
        checkpointStore: any CrawlingCheckpointStore,
        chatNormalizer: ChatNormalizer = ChatNormalizer(),
        chatIdGenerator: ChatIdGenerator = ChatIdGenerator()
    ) {
        self.integration = integration
        self.messageSyncOrchestrator = messageSyncOrchestrator
        self.checkpointStore = checkpointStore
        self.chatNormalizer = chatNormalizer
        self.chatIdGenerator = chatIdGenerator
    }

    func syncChats() async -> CrawlingResult<Void> {
        switch await integration.resolveFlowState() {
        case .failure(let error):
            return .failure(error)
        case .success:
            break
        }

        switch await integration.listChats() {
        case .failure(let error):
            return .failure(error)
        case .success(let chats):
            let normalizedChats = chats.map { chatNormalizer.normalize($0) }
            let generatedIdentifiers = normalizedChats.map { chatIdGenerator.makeIdentifier(from: $0.title) }

            for (chat, identifier) in zip(chats, generatedIdentifiers) {
                _ = identifier
                switch await integration.selectChat(chat) {
                case .failure(let error):
                    return .failure(error)
                case .success:
                    break
                }

                switch await messageSyncOrchestrator.syncMessages() {
                case .failure(let error):
                    return .failure(error)
                case .success:
                    break
                }
            }

            let checkpoint = CrawlingCheckpoint(
                lastChatIdentifier: generatedIdentifiers.last,
                lastMessageIdentifier: nil,
                updatedAt: .init()
            )
            return await checkpointStore.save(checkpoint)
        }
    }
}
