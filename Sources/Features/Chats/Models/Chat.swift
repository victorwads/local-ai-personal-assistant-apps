import Foundation

struct Chat: PersistableModel, Equatable, Sendable {
    @DocumentID var id: String?
    var source: String?
    var title: String
    var lastMessageText: String?
    var lastMessageAt: Date?
    var handled: Bool
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}
