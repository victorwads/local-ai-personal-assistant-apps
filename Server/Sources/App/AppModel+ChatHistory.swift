import Foundation

extension AppModel {
    func loadChatHistory() {
        Task { [weak self] in
            guard let self else { return }
            do {
                guard let payload = try await chatHistoryRepository.load() else {
                    return
                }
                let migratedPayload = migratePersistedChatHistory(payload)
                let allowedChatStatesByChatId = migratedPayload.chatStatesByChatId.filter { !self.isBlocked($0.value.chat.name) }
                self.memoryStore.replaceAllChatStates(allowedChatStatesByChatId)
                self.appendLog("Loaded persisted chat history for \(allowedChatStatesByChatId.count) chats.")
                if migratedPayload != payload {
                    try await chatHistoryRepository.save(migratedPayload)
                    self.appendLog("Migrated persisted chat history to canonical chat IDs.")
                }
            } catch {
                self.appendLog("Failed to load persisted chat history: \(error.localizedDescription)", level: .warning)
            }
        }
    }

    func bindChatHistoryPersistence() {
        chatHistoryListenerId = memoryStore.addEventListener { [weak self] event in
            guard let self else { return }
            guard case .chatStateUpdated = event else {
                return
            }
            self.schedulePersistChatHistory()
        }
    }

    private func schedulePersistChatHistory() {
        chatHistoryPersistTask?.cancel()
        chatHistoryPersistTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(750))
            await self.persistChatHistory()
        }
    }

    private func persistChatHistory() async {
        let snapshot = memoryStore.snapshotChatStatesById()
        let payload = PersistedChatHistory(
            version: 1,
            updatedAt: Date(),
            chatStatesByChatId: snapshot
        )

        do {
            try await chatHistoryRepository.save(payload)
        } catch {
            appendLog("Failed to persist chat history: \(error.localizedDescription)", level: .warning)
        }
    }

    private func migratePersistedChatHistory(_ payload: PersistedChatHistory) -> PersistedChatHistory {
        var normalizedStatesByChatId: [String: ChatState] = [:]

        for state in payload.chatStatesByChatId.values {
            let canonicalChatId = WhatsAppConversationIdentity.canonicalChatId(for: state.chat.name)
            let normalizedChat = state.chat.replacing(id: canonicalChatId)
            let normalizedState = state.replacing(
                chat: normalizedChat,
                messages: state.messages.map { $0.replacing(chatId: canonicalChatId) }
            )
            normalizedStatesByChatId[canonicalChatId] = normalizedState
        }

        return PersistedChatHistory(
            version: payload.version,
            updatedAt: payload.updatedAt,
            chatStatesByChatId: normalizedStatesByChatId
        )
    }
}
