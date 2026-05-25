import Foundation

struct CrawlingCheckpoint: Codable, Equatable, Sendable {
    let lastChatIdentifier: String?
    let lastMessageIdentifier: String?
    let updatedAt: Date
}

protocol CrawlingCheckpointStore {
    func load() async -> CrawlingResult<CrawlingCheckpoint?>
    func save(_ checkpoint: CrawlingCheckpoint) async -> CrawlingResult<Void>
}

actor InMemoryCrawlingCheckpointStore: CrawlingCheckpointStore {
    private var checkpoint: CrawlingCheckpoint?

    func load() async -> CrawlingResult<CrawlingCheckpoint?> {
        .success(checkpoint)
    }

    func save(_ checkpoint: CrawlingCheckpoint) async -> CrawlingResult<Void> {
        self.checkpoint = checkpoint
        return .success(())
    }
}
