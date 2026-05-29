import FirebaseFirestore
import Foundation

final class FirestoreChatRepository: ChatRepository {
    private final class ChatStore: FirebaseRepository<Chat> {
        init(scope: FirebaseProfileScope, firestore: Firestore) {
            super.init(
                entityName: "Chat",
                path: .profileScoped(scope: scope, collection: "Chats"),
                firestore: firestore,
                readSource: .cacheOnly
            )
        }
    }

    private final class MessageStore: FirebaseRepository<ChatMessage> {
        init(scope: FirebaseProfileScope, firestore: Firestore) {
            super.init(
                entityName: "ChatMessage",
                path: .profileScoped(scope: scope, collection: "ChatMessages"),
                firestore: firestore,
                readSource: .cacheOnly
            )
        }
    }

    private let chatStore: ChatStore
    private let messageStore: MessageStore

    init(scope: FirebaseProfileScope, firestore: Firestore = .firestore()) {
        self.chatStore = ChatStore(scope: scope, firestore: firestore)
        self.messageStore = MessageStore(scope: scope, firestore: firestore)
    }

    func getChat(id: String) async throws -> Chat? {
        try await chatStore.getById(id)
    }

    func listChats() async throws -> [Chat] {
        try await chatStore.getAll(includeDeleted: false)
    }

    func upsertChat(_ chat: Chat) async throws {
        _ = try await chatStore.save(chat, merge: true)
    }

    func deleteChat(id: String) async throws {
        try await chatStore.delete(id)
    }

    func getMessage(id: String) async throws -> ChatMessage? {
        try await messageStore.getById(id)
    }

    func listMessages(chatId: String) async throws -> [ChatMessage] {
        let all = try await messageStore.getAll(includeDeleted: false)
        return all.filter { $0.chatId == chatId }
    }

    func upsertMessage(_ message: ChatMessage) async throws {
        _ = try await messageStore.save(message, merge: true)
    }

    func upsertMessages(_ messages: [ChatMessage]) async throws {
        try await messageStore.saveAll(messages)
    }

    func existingMessageIds(chatId: String) async throws -> Set<String> {
        let messages = try await listMessages(chatId: chatId)
        return Set(messages.compactMap(\.id))
    }

    func deleteMessage(id: String) async throws {
        try await messageStore.delete(id)
    }
}
