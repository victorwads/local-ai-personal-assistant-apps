import Foundation

struct NicknameEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let chatId: String
    let chatName: String
    let nickname: String
    let createdAt: Date
}

