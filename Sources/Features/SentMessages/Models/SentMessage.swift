import Foundation

struct SentMessage: PersistableModel, Equatable, Sendable {
    @DocumentID var id: String?
    var issueId: String
    var targetKind: SentMessageTargetKind
    var targetId: String
    var targetTitle: String
    var messages: [String]
    var status: SentMessageStatus
    var providerMessageIds: [String]
    var errorMessage: String?
}

enum SentMessageTargetKind: String, Codable, Equatable, Sendable, CaseIterable {
    case chat
    case email
    case unknown
}

enum SentMessageStatus: String, Codable, Equatable, Sendable, CaseIterable {
    case pending
    case sent
    case failed
}
