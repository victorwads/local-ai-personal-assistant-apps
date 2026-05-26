import Foundation

struct ClientVoiceMessage: PersistableModel, Equatable, Sendable {
    @DocumentID var id: String?
    var issueId: String
    var kind: ClientVoiceMessageKind
    var text: String?
    var audioReference: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}

enum ClientVoiceMessageKind: String, Codable, Equatable, Sendable {
    case speakToClient
    case askToClient
    case transcribedClientReply
    case assistantPrompt
}
