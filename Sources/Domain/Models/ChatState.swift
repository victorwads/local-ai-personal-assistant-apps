import Foundation

struct ChatState: Codable, Equatable {
    let chat: ConversationSummary
    let messages: [Message]
    let composeFocused: Bool
    let canSendText: Bool
}
