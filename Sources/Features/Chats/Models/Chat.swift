import Foundation

struct Chat: Codable, Equatable, Sendable {
    let id: String
    let source: String?
    let title: String
    let lastMessageText: String?
    let lastMessageAt: Date?
    let handled: Bool
}
