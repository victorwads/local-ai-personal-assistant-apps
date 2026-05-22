import Foundation
import FirebaseFirestore
import os

enum MemoriesRepositoryError: LocalizedError {
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

actor MemoriesRepository {
    struct SaveResult: Equatable {
        let entry: MemoryEntry
        let created: Bool
        let updated: Bool
    }

    private let profileID: String
    private var entries: [MemoryEntry] = []
    private var listenerRegistration: ListenerRegistrationWrapper?
    private let logger = Logger(subsystem: "dev.wads.AssistantMCPServer", category: "MemoriesRepository")

    init(profileID: String) {
        self.profileID = profileID
    }

    func startListening() {
        let firestore = Firestore.firestore()
        let path = FirestoreCollections.Memories(profileID)
        
        let registration = firestore.collection(path).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let snapshot = snapshot else {
                if let error = error {
                    self.logger.error("Error listening to memories: \(error.localizedDescription)")
                }
                return
            }
            
            var newEntries: [MemoryEntry] = []
            for document in snapshot.documents {
                if let entry = MemoryEntry.fromFirestoreData(document.data()) {
                    newEntries.append(entry)
                }
            }
            
            Task {
                await self.updateEntries(newEntries)
            }
        }
        
        self.listenerRegistration = ListenerRegistrationWrapper(registration)
    }

    private func updateEntries(_ newEntries: [MemoryEntry]) {
        self.entries = newEntries
        NotificationCenter.default.post(name: .memoriesRepositoryDidChange, object: nil)
    }

    func list() -> [MemoryEntry] {
        entries.sorted { $0.updatedAt > $1.updatedAt }
    }

    func get(key: String?) throws -> MemoryEntry {
        let trimmedKey = (key ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedKey.isEmpty {
            throw MemoriesRepositoryError.missingParameter("key")
        }

        guard let found = entries.first(where: { $0.key.lowercased() == trimmedKey.lowercased() }) else {
            throw MemoriesRepositoryError.invalidParameter("Memory not found")
        }

        return found
    }

    func search(query: String?, limit: Int = 3) -> [MemorySearchResult] {
        let trimmedQuery = (query ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let all = entries

        if trimmedQuery.isEmpty {
            return all
                .sorted { $0.updatedAt > $1.updatedAt }
                .prefix(max(1, limit))
                .map { MemorySearchResult(entry: $0, score: 1) }
        }

        let ranked = all
            .map { entry -> MemorySearchResult in
                let score = TextSimilarity.bestScore(
                    query: trimmedQuery,
                    candidates: [entry.key, entry.content]
                )
                return MemorySearchResult(entry: entry, score: score)
            }
            .sorted {
                if $0.score == $1.score {
                    return $0.entry.updatedAt > $1.entry.updatedAt
                }
                return $0.score > $1.score
            }

        return Array(ranked.prefix(max(1, limit)))
    }

    func save(key: String?, content: String?) async throws -> SaveResult {
        let trimmedKey = (key ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedKey.isEmpty {
            throw MemoriesRepositoryError.missingParameter("key")
        }

        let trimmedContent = (content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedContent.isEmpty {
            throw MemoriesRepositoryError.missingParameter("content")
        }

        let all = entries
        let now = Date()

        let matchingIndexes = all.indices.filter { all[$0].key.lowercased() == trimmedKey.lowercased() }
        if let firstIndex = matchingIndexes.first {
            let existing = all[firstIndex]
            let updatedEntry = MemoryEntry(
                id: existing.id,
                key: trimmedKey,
                content: trimmedContent,
                createdAt: existing.createdAt,
                updatedAt: now
            )
            
            try await persistEntry(updatedEntry)
            return SaveResult(entry: updatedEntry, created: false, updated: true)
        }

        let entry = MemoryEntry(
            id: UUID(),
            key: trimmedKey,
            content: trimmedContent,
            createdAt: now,
            updatedAt: now
        )
        try await persistEntry(entry)
        return SaveResult(entry: entry, created: true, updated: false)
    }

    func delete(id: UUID?) async throws -> Bool {
        guard let id else {
            throw MemoriesRepositoryError.missingParameter("id")
        }

        let firestore = Firestore.firestore()

        let path = FirestoreCollections.Memories(profileID) + "/\(id.uuidString)"
        try await firestore.document(path).delete()
        return true
    }

    func delete(key: String?) async throws -> Bool {
        let trimmedKey = (key ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedKey.isEmpty {
            throw MemoriesRepositoryError.missingParameter("key")
        }

        guard let found = entries.first(where: { $0.key.lowercased() == trimmedKey.lowercased() }) else {
            return false
        }
        
        return try await delete(id: found.id)
    }

    private func persistEntry(_ entry: MemoryEntry) async throws {
        let firestore = Firestore.firestore()
        let path = FirestoreCollections.Memories(profileID) + "/\(entry.id.uuidString)"
        try await firestore.document(path).setData(entry.toFirestoreData(), merge: true)
    }
}
