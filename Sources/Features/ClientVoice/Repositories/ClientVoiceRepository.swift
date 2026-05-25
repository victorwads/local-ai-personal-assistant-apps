import Foundation

protocol ClientVoiceRepository {
    func fetchMessage(id: String) async throws -> ClientVoiceMessage?
    func listMessages(issueId: String) async throws -> [ClientVoiceMessage]
    func saveMessage(_ message: ClientVoiceMessage) async throws
    func deleteMessage(id: String) async throws
}
