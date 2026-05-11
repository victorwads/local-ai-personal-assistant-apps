import Foundation

extension AppModel {
    func sendMessageToSelectedChat() async {
        let trimmedMessage = messageDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else {
            appendLog("Cannot send an empty message.", level: .warning)
            return
        }

        guard let selectedChatState else {
            appendLog("No selected conversation available to send a message.", level: .warning)
            return
        }

        guard prepareForWhatsAppInspection() else {
            return
        }

        isSendingMessage = true
        defer { isSendingMessage = false }

        do {
            try await sendMessage(trimmedMessage, to: selectedChatState.chat.id)
            messageDraft = ""
        } catch {
            appendLog("Failed to send message: \(error.localizedDescription)", level: .error)
        }
    }

    func sendMessage(_ text: String, to conversationId: String) async throws {
        let trimmedMessage = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else {
            throw MCPServerError.invalidParameter("text")
        }

        guard let conversation = memoryStore.conversation(for: conversationId) else {
            throw MCPServerError.invalidParameter("chatId")
        }

        guard !isBlocked(conversation.name) else {
            throw MCPServerError.invalidRequest
        }

        guard prepareForWhatsAppInspection() else {
            throw MCPServerError.invalidRequest
        }

        try interactor.selectConversation(conversation, using: accessibility)
        try await Task.sleep(for: .milliseconds(650))

        let snapshot = try accessibility.captureWhatsAppSnapshot(maxDepth: 14)
        try interactor.sendMessage(trimmedMessage, in: snapshot, using: accessibility)
        appendLog("Sent message to \(conversation.name).")

        try await Task.sleep(for: .milliseconds(500))

        let refreshedSnapshot = try accessibility.captureWhatsAppSnapshot(maxDepth: 14)
        let refreshedState = parser.parse(snapshot: refreshedSnapshot, messageLimit: 10)
        writeDebugArtifacts(snapshot: refreshedSnapshot, screenState: refreshedState, prefix: "send-\(conversation.id)")
        memoryStore.replaceConversations(refreshedState.conversations)
        updateSelectedChatState(from: refreshedState, preferredConversation: conversation)
    }
}
