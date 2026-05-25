import Foundation

final class WhatsAppCrawlerWorker {
    private let chatSyncOrchestrator: ChatSyncOrchestrator

    init(chatSyncOrchestrator: ChatSyncOrchestrator) {
        self.chatSyncOrchestrator = chatSyncOrchestrator
    }

    func runCycle() async -> CrawlingResult<Void> {
        await chatSyncOrchestrator.syncChats()
    }
}
