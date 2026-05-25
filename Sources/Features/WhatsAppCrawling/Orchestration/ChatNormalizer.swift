import Foundation

struct NormalizedChat: Equatable, Sendable {
    let title: String
    let unreadCount: Int?
    let lastMessageText: String?
    let lastMessageTimeText: String?
    let rawPosition: Int?
}

struct ChatNormalizer {
    func normalize(_ chat: CrawledChat) -> NormalizedChat {
        NormalizedChat(
            title: chat.rawTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            unreadCount: chat.unreadCount,
            lastMessageText: chat.lastMessageText?.trimmingCharacters(in: .whitespacesAndNewlines),
            lastMessageTimeText: chat.lastMessageTimeText?.trimmingCharacters(in: .whitespacesAndNewlines),
            rawPosition: chat.rawPosition
        )
    }
}
