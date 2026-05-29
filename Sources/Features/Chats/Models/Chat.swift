import Foundation

struct Chat: PersistableModel, Equatable, Sendable {
    @DocumentID var id: String?
    var title: String
    var lastMessagePreview: String?
    var lastMessageTimeText: String?
    var unreadCount: Int
    var stateHash: String
}
