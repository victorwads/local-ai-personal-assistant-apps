import Foundation
import FirebaseFirestore
import CryptoKit
import os

actor ChatHistoryRepository {
    private let profileID: String
    private let logger = Logger(subsystem: "dev.wads.AssistantMCPServer", category: "ChatHistoryRepository")

    init(profileID: String) {
        self.profileID = profileID
    }

    func load() async throws -> PersistedChatHistory? {
        let firestore = Firestore.firestore()

        let chatsPath = FirestoreCollections.WhatszapChats(profileID)

        // 1. Fetch chats from disk cache — zero server reads
        let chatSnapshot = try await firestore.collection(chatsPath).getDocuments(source: .cache)
        var chatStatesByChatId: [String: ChatState] = [:]

        for chatDoc in chatSnapshot.documents {
            let data = chatDoc.data()
            let chatID = data["chatId"] as? String ?? chatDoc.documentID

            // Reconstruct ConversationSummary (stable persistent fields only)
            let name = data["name"] as? String ?? ""
            let unreadCount = data["unreadCount"] as? Int ?? 0
            let isPinned = data["isPinned"] as? Bool ?? false
            let lastMessagePreview = data["lastMessagePreview"] as? String
            let lastMessageAtText = data["lastMessageAtText"] as? String

            let lastMessageDirection: MessageDirection
            if let dirStr = data["lastMessageDirection"] as? String {
                lastMessageDirection = MessageDirection(rawValue: dirStr) ?? .unknown
            } else {
                lastMessageDirection = .unknown
            }

            let lastMessageStatus: MessageStatus
            if let statusStr = data["lastMessageStatus"] as? String {
                lastMessageStatus = MessageStatus(rawValue: statusStr) ?? .unknown
            } else {
                lastMessageStatus = .unknown
            }

            let chat = ConversationSummary(
                id: chatID,
                accessibilityPath: [],   // ephemeral — not persisted
                name: name,
                unreadCount: unreadCount,
                isPinned: isPinned,
                isSelected: false,       // ephemeral — not persisted
                lastMessagePreview: lastMessagePreview,
                lastMessageAtText: lastMessageAtText,
                lastMessageDirection: lastMessageDirection,
                lastMessageStatus: lastMessageStatus,
                isTyping: false          // ephemeral — not persisted
            )

            // 2. Fetch messages for this chat from disk cache (.cache)
            let messagesPath = FirestoreCollections.Messages(profileID, chatID: chatID)
            let messagesSnapshot = try await firestore.collection(messagesPath).getDocuments(source: .cache)

            var messages: [Message] = []
            for msgDoc in messagesSnapshot.documents {
                if let msg = Message.fromFirestoreData(msgDoc.data()) {
                    messages.append(msg)
                }
            }

            // Sort by timestamp, fall back to id comparison
            messages.sort { (m1, m2) -> Bool in
                if let t1 = m1.timestamp, let t2 = m2.timestamp {
                    return t1 < t2
                }
                return m1.id < m2.id
            }

            let state = ChatState(
                chat: chat,
                messages: messages,
                composeFocused: false,   // ephemeral — not persisted
                canSendText: true        // ephemeral — not persisted
            )
            chatStatesByChatId[chatID] = state
        }

        if chatStatesByChatId.isEmpty {
            return nil
        }

        return PersistedChatHistory(
            version: 1,
            updatedAt: Date(),
            chatStatesByChatId: chatStatesByChatId
        )
    }

    func save(_ payload: PersistedChatHistory) async throws {
        let firestore = Firestore.firestore()

        for (chatID, chatState) in payload.chatStatesByChatId {
            let chat = chatState.chat

            // Only persist stable, non-ephemeral fields
            var chatData: [String: Any] = [
                "chatId": chatID,
                "name": chat.name,
                "unreadCount": chat.unreadCount,
                "isPinned": chat.isPinned,
                "lastMessageDirection": chat.lastMessageDirection.rawValue,
                "lastMessageStatus": chat.lastMessageStatus.rawValue,
                "messageCount": chatState.messages.count,
                "updatedAt": Timestamp(date: Date())
            ]
            if let preview = chat.lastMessagePreview {
                chatData["lastMessagePreview"] = preview
            }
            if let atText = chat.lastMessageAtText {
                chatData["lastMessageAtText"] = atText
            }

            let chatDocPath = FirestoreCollections.WhatszapChatDocument(profileID, chatID: chatID)
            try await firestore.document(chatDocPath).setData(chatData, merge: true)

            // Save each message with hashed document ID
            let messagesCollectionPath = FirestoreCollections.Messages(profileID, chatID: chatID)
            for message in chatState.messages {
                let msgHash = sha256Hash(message.id)
                let msgDocPath = "\(messagesCollectionPath)/\(msgHash)"
                try await firestore.document(msgDocPath).setData(message.toFirestoreData(), merge: true)
            }
        }
    }

    func clear() async throws {
        self.logger.info("Clear called on ChatHistoryRepository for profileID: \(self.profileID)")
    }

    private func sha256Hash(_ string: String) -> String {
        let inputData = Data(string.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
