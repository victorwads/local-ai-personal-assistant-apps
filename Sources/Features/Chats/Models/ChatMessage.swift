import Foundation

struct ChatMessage: Codable, Equatable, Sendable {
    let id: String
    let chatId: String
    let sourceMessageId: String?
    let text: String?
    let authorName: String?
    let sentAt: Date?
    let handled: Bool
}
