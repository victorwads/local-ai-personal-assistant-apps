import Foundation
import FirebaseFirestore
import os

actor ClientPromptWaitRepository {
    static let shared = ClientPromptWaitRepository()

    // MARK: - Types

    private struct PromptEntry {
        let id: UUID
        let createdAt: Date
        let text: String

        func toFirestoreData() -> [String: Any] {
            [
                "id": id.uuidString,
                "createdAt": Timestamp(date: createdAt),
                "text": text
            ]
        }

        static func fromFirestoreData(_ data: [String: Any]) -> PromptEntry? {
            guard let idStr = data["id"] as? String,
                  let id = UUID(uuidString: idStr),
                  let text = data["text"] as? String else { return nil }
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            return PromptEntry(id: id, createdAt: createdAt, text: text)
        }
    }

    // MARK: - State

    private let profileID: String
    private var activeWaitIDs: Set<UUID> = []
    private var queuedEntries: [PromptEntry] = []
    private var listenerRegistration: ListenerRegistrationWrapper?
    private let logger = Logger(subsystem: "dev.wads.AssistantMCPServer", category: "ClientPromptWaitRepository")

    init(profileID: String = "00000000-0000-0000-0000-000000000001") {
        self.profileID = profileID
    }

    // MARK: - Real-time listener

    func startListening() {
        guard listenerRegistration == nil else { return }
        let firestore = Firestore.firestore()
        let path = FirestoreCollections.PromptQueue(profileID)

        let registration = firestore.collection(path)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                guard let snapshot else {
                    if let error { self.logger.error("PromptQueue listener error: \(error.localizedDescription)") }
                    return
                }
                let updated = snapshot.documents.compactMap { PromptEntry.fromFirestoreData($0.data()) }
                Task { await self.updateQueue(updated) }
            }
        listenerRegistration = ListenerRegistrationWrapper(registration)
    }

    private func updateQueue(_ entries: [PromptEntry]) {
        queuedEntries = entries
        NotificationCenter.default.post(name: .clientPromptWaitRepositoryDidChange, object: nil)
    }

    // MARK: - Wait tracking (in-memory only — ephemeral)

    func beginWait() -> UUID {
        let id = UUID()
        activeWaitIDs.insert(id)
        return id
    }

    func endWait(id: UUID) {
        activeWaitIDs.remove(id)
    }

    func pendingWaitCount() -> Int {
        max(activeWaitIDs.count, queuedEntries.isEmpty ? 0 : 1)
    }

    // MARK: - Prompt Queue

    func submitPrompt(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let entry = PromptEntry(id: UUID(), createdAt: Date(), text: trimmed)
        Task { await self.enqueue(entry) }
        clearDraft()
    }

    func consumePrompt() -> String? {
        guard let first = queuedEntries.first else { return nil }
        Task { await self.dequeue(id: first.id) }
        return first.text
    }

    func queuedPromptCount() -> Int {
        queuedEntries.count
    }

    // MARK: - Draft (hands-free prompt window)

    func setDraft(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task { await self.writeDraft(trimmed) }
    }

    func getDraft() -> String? {
        // Draft is read from the listener's initial snapshot; here we read from cache synchronously
        // via the listener-populated state. For immediate UI needs, returns nil if not yet loaded.
        // Callers that need the persisted draft should call getDraftAsync().
        nil
    }

    func getDraftAsync() async -> String? {
        let firestore = Firestore.firestore()
        let path = FirestoreCollections.PromptStateDocument(profileID)
        guard let snapshot = try? await firestore.document(path).getDocument(source: .cache),
              let value = snapshot.data()?["draft"] as? String,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func clearDraft() {
        Task { await self.writeDraft(nil) }
    }

    // MARK: - Firestore helpers

    private func enqueue(_ entry: PromptEntry) async {
        let firestore = Firestore.firestore()
        let path = FirestoreCollections.PromptQueue(profileID) + "/\(entry.id.uuidString)"
        do {
            try await firestore.document(path).setData(entry.toFirestoreData())
        } catch {
            logger.error("Failed to enqueue prompt: \(error.localizedDescription)")
        }
    }

    private func dequeue(id: UUID) async {
        let firestore = Firestore.firestore()
        let path = FirestoreCollections.PromptQueue(profileID) + "/\(id.uuidString)"
        do {
            try await firestore.document(path).delete()
        } catch {
            logger.error("Failed to dequeue prompt \(id): \(error.localizedDescription)")
        }
    }

    private func writeDraft(_ text: String?) async {
        let firestore = Firestore.firestore()
        let path = FirestoreCollections.PromptStateDocument(profileID)
        do {
            if let text {
                try await firestore.document(path).setData(["draft": text], merge: true)
            } else {
                try await firestore.document(path).setData(["draft": FieldValue.delete()], merge: true)
            }
        } catch {
            logger.error("Failed to write prompt draft: \(error.localizedDescription)")
        }
    }
}

// MARK: - Notification

extension Notification.Name {
    static let clientPromptWaitRepositoryDidChange = Notification.Name("clientPromptWaitRepositoryDidChange")
}
