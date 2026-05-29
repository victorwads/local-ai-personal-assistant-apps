import Foundation

struct ChatMessage: PersistableModel, Equatable, Sendable {
    enum Kind: String, Codable, Equatable, Sendable {
        case text
        case image
        case sticker
        case audio
        case unknown
    }

    @DocumentID var id: String?
    var chatId: String
    var author: String?
    var text: String?
    var kind: Kind
    var dateTime: Date?
    var quotedMessageText: String?
    var quotedMessageAuthor: String?
    var handled: Bool = false

    init(
        id: String?,
        chatId: String,
        author: String?,
        text: String?,
        kind: Kind,
        dateTime: Date?,
        quotedMessageText: String?,
        quotedMessageAuthor: String?,
        handled: Bool = false
    ) {
        self.id = id
        self.chatId = chatId
        self.author = author
        self.text = text
        self.kind = kind
        self.dateTime = dateTime
        self.quotedMessageText = quotedMessageText
        self.quotedMessageAuthor = quotedMessageAuthor
        self.handled = handled
    }
}
