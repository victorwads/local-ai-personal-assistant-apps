import Foundation

struct ChatMessage: PersistableModel, Equatable, Sendable {
    @DocumentID var id: String?
    var chatId: String
    var sourceMessageId: String?
    var text: String?
    var authorName: String?
    var sentAt: Date?
    var handled: Bool
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}
