import Foundation
import FirebaseFirestore
import os

enum NicknamesRepositoryError: LocalizedError {
    case missingParameter(String)
    case invalidParameter(String)

    var errorDescription: String? {
        switch self {
        case .missingParameter(let name):
            return "Missing parameter: \(name)"
        case .invalidParameter(let message):
            return message
        }
    }
}

actor NicknamesRepository {
    struct SaveResult: Codable, Equatable {
        let entry: NicknameEntry
        let created: Bool
    }

    private let profileID: String
    private var entries: [NicknameEntry] = []
    private var listenerRegistration: ListenerRegistrationWrapper?
    private let logger = Logger(subsystem: "dev.wads.AssistantMCPServer", category: "NicknamesRepository")

    init(profileID: String) {
        self.profileID = profileID
    }

    func startListening() {
        let firestore = Firestore.firestore()
        let path = FirestoreCollections.Nicknames(profileID)
        
        let registration = firestore.collection(path).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let snapshot = snapshot else {
                if let error = error {
                    self.logger.error("Error listening to nicknames: \(error.localizedDescription)")
                }
                return
            }
            
            var newEntries: [NicknameEntry] = []
            for document in snapshot.documents {
                if let entry = NicknameEntry.fromFirestoreData(document.data()) {
                    newEntries.append(entry)
                }
            }
            
            Task {
                await self.updateEntries(newEntries)
            }
        }
        
        self.listenerRegistration = ListenerRegistrationWrapper(registration)
    }

    private func updateEntries(_ newEntries: [NicknameEntry]) {
        self.entries = newEntries
        NotificationCenter.default.post(name: .nicknamesRepositoryDidChange, object: nil)
    }

    func list(query: String? = nil) -> [NicknameEntry] {
        let all = entries

        let trimmedQuery = (query ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return all.sorted { $0.createdAt > $1.createdAt }
        }

        let normalizedQuery = normalizedNicknameSearchText(trimmedQuery)

        let exactMatches = all.filter {
            normalizedNicknameSearchText($0.nickname) == normalizedQuery
                || normalizedNicknameSearchText($0.originalName) == normalizedQuery
                || normalizedNicknameSearchText($0.chatId ?? "") == normalizedQuery
        }
        if !exactMatches.isEmpty {
            let exactOriginalNames = Set(exactMatches.map { normalizedNicknameSearchText($0.originalName) })
            let exactChatIds = Set(exactMatches.compactMap { $0.chatId }.map(normalizedNicknameSearchText))
            return all
                .filter {
                    exactOriginalNames.contains(normalizedNicknameSearchText($0.originalName))
                        || exactChatIds.contains(normalizedNicknameSearchText($0.chatId ?? ""))
                }
                .sorted { $0.createdAt > $1.createdAt }
        }

        let matchingOriginalNames = Set(
            all
                .filter {
                    normalizedNicknameSearchText($0.nickname).contains(normalizedQuery)
                        || normalizedNicknameSearchText($0.originalName).contains(normalizedQuery)
                        || normalizedNicknameSearchText($0.chatId ?? "").contains(normalizedQuery)
                }
                .map { normalizedNicknameSearchText($0.originalName) }
        )
        guard !matchingOriginalNames.isEmpty else {
            return []
        }

        return all
            .filter { matchingOriginalNames.contains(normalizedNicknameSearchText($0.originalName)) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func save(originalName: String?, chatId: String?, nickname: String?) async throws -> SaveResult {
        let trimmedOriginalName = (originalName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedOriginalName.isEmpty {
            throw NicknamesRepositoryError.missingParameter("originalName")
        }

        let trimmedNickname = (nickname ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedNickname.isEmpty {
            throw NicknamesRepositoryError.missingParameter("nickname")
        }

        let trimmedChatId = normalizedOptionalString(chatId)

        let all = entries
        if let index = all.firstIndex(where: {
            normalizedNicknameSearchText($0.originalName) == normalizedNicknameSearchText(trimmedOriginalName)
                && normalizedNicknameSearchText($0.nickname) == normalizedNicknameSearchText(trimmedNickname)
                && normalizedOptionalString($0.chatId) == trimmedChatId
        }) {
            return SaveResult(entry: all[index], created: false)
        }

        if let index = all.firstIndex(where: {
            normalizedNicknameSearchText($0.originalName) == normalizedNicknameSearchText(trimmedOriginalName)
                && normalizedNicknameSearchText($0.nickname) == normalizedNicknameSearchText(trimmedNickname)
        }) {
            if all[index].chatId == nil, let trimmedChatId {
                let updatedEntry = NicknameEntry(
                    id: all[index].id,
                    originalName: all[index].originalName,
                    nickname: all[index].nickname,
                    chatId: trimmedChatId,
                    createdAt: all[index].createdAt
                )
                try await persistEntry(updatedEntry)
                return SaveResult(entry: updatedEntry, created: false)
            }
            return SaveResult(entry: all[index], created: false)
        }

        let entry = NicknameEntry(
            id: UUID(),
            originalName: trimmedOriginalName,
            nickname: trimmedNickname,
            chatId: trimmedChatId,
            createdAt: Date()
        )
        try await persistEntry(entry)
        return SaveResult(entry: entry, created: true)
    }

    func delete(id: UUID?) async throws -> Bool {
        guard let id else {
            throw NicknamesRepositoryError.missingParameter("id")
        }

        let firestore = Firestore.firestore()

        let path = FirestoreCollections.Nicknames(profileID) + "/\(id.uuidString)"
        try await firestore.document(path).delete()
        return true
    }

    private func persistEntry(_ entry: NicknameEntry) async throws {
        let firestore = Firestore.firestore()
        let path = FirestoreCollections.Nicknames(profileID) + "/\(entry.id.uuidString)"
        try await firestore.document(path).setData(entry.toFirestoreData(), merge: true)
    }

    private func normalizedNicknameSearchText(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedOptionalString(_ value: String?) -> String? {
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

