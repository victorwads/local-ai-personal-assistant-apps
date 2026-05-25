import Foundation

struct ClientVoiceMessage: Codable, Equatable, Sendable {
    let id: String
    let issueId: String
    let kind: ClientVoiceMessageKind
    let text: String?
    let audioReference: String?
    let createdAt: Date
}

enum ClientVoiceMessageKind: String, Codable, Equatable, Sendable {
    case speakToClient
    case askToClient
    case transcribedClientReply
    case assistantPrompt
}
