import Foundation

struct SensitiveDataUsage: PersistableModel, Equatable, Sendable {
    @DocumentID var id: String?
    var key: String
    var issueId: String?
    var chatId: String?
    var reason: String?
    var usedAt: Date
}
