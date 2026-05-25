import Foundation

final class MessageSyncOrchestrator {
    private let integration: any WhatsAppCrawlingIntegration
    private let messageNormalizer: MessageNormalizer

    init(
        integration: any WhatsAppCrawlingIntegration,
        messageNormalizer: MessageNormalizer = MessageNormalizer()
    ) {
        self.integration = integration
        self.messageNormalizer = messageNormalizer
    }

    func syncMessages() async -> CrawlingResult<Void> {
        switch await integration.listMessages() {
        case .success(let messages):
            _ = messages.map { messageNormalizer.normalize($0) }
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
}
