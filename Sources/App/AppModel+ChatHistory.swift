import Foundation

extension AppModel {
    func loadChatHistory() {
        do {
            guard let payload = try chatHistoryRepository.load() else {
                return
            }
            memoryStore.replaceAllChatStates(payload.chatStatesByChatId)
            appendLog("Loaded persisted chat history for \(payload.chatStatesByChatId.count) chats.")
        } catch {
            appendLog("Failed to load persisted chat history: \(error.localizedDescription)", level: .warning)
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
            try chatHistoryRepository.save(payload)
        } catch {
            appendLog("Failed to persist chat history: \(error.localizedDescription)", level: .warning)
        }
    }
}

