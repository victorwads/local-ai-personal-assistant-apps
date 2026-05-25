import Foundation

struct SensitiveDataUsage: Codable, Equatable, Sendable {
    let id: String
    let sensitiveDataItemId: String
    let issueId: String?
    let chatId: String?
    let reason: String?
    let usedAt: Date
}
