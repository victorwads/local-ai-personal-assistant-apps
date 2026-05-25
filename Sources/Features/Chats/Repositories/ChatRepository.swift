import Foundation

protocol ChatRepository {
    func fetchChat(id: String) async throws -> Chat?
    func listChats() async throws -> [Chat]
    func saveChat(_ chat: Chat) async throws
    func deleteChat(id: String) async throws

    func fetchMessage(id: String) async throws -> ChatMessage?
    func listMessages(chatId: String) async throws -> [ChatMessage]
    func saveMessage(_ message: ChatMessage) async throws
    func deleteMessage(id: String) async throws
}
