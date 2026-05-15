import Foundation

enum MessageDirection: String, Codable, Equatable {
    case incoming
    case outgoing
    case unknown
}

enum MessageKind: String, Codable, Equatable {
    case text
    case voice
    case image
    case document
    case deleted
    case unknown
}

enum MessageStatus: String, Codable, Equatable {
    case sent
    case delivered
    case read
    case unknown
}

struct Message: Identifiable, Codable, Equatable {
    let id: String
    let chatId: String
    let direction: MessageDirection
    let kind: MessageKind
    let text: String?
    let durationSeconds: Double?
    let timestamp: Date?
    let status: MessageStatus
    let rawAccessibilityText: String
}
