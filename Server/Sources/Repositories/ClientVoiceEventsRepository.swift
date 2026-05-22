import Foundation
import FirebaseFirestore
import os

actor ClientVoiceEventsRepository {
    static let shared = ClientVoiceEventsRepository()

    private let profileID: String
    private var entries: [ClientVoiceEvent] = []
    private var listenerRegistration: ListenerRegistrationWrapper?
    private var pendingWaitersById: [UUID: CheckedContinuation<String, Error>] = [:]
    private let logger = Logger(subsystem: "dev.wads.AssistantMCPServer", category: "ClientVoiceEventsRepository")

    /// Default shared instance uses the primary profile ID.
    init(profileID: String = "00000000-0000-0000-0000-000000000001") {
        self.profileID = profileID
    }

    // MARK: - Listener

    func startListening() {
        guard listenerRegistration == nil else { return }
        let firestore = Firestore.firestore()
        let path = FirestoreCollections.VoiceEvents(profileID)

        let registration = firestore.collection(path)
            .order(by: "createdAt", descending: true)
            .limit(to: 300)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                guard let snapshot else {
                    if let error { self.logger.error("VoiceEvents listener error: \(error.localizedDescription)") }
                    return
                }
                let updated = snapshot.documents.compactMap { ClientVoiceEvent.fromFirestoreData($0.data()) }
                Task { await self.updateEntries(updated) }
            }
        listenerRegistration = ListenerRegistrationWrapper(registration)
    }

    private func updateEntries(_ newEntries: [ClientVoiceEvent]) {
        entries = newEntries.sorted { $0.createdAt > $1.createdAt }
        NotificationCenter.default.post(name: .clientVoiceEventsRepositoryDidChange, object: nil)

        // Resume any waiters whose ask has been answered
        for event in entries where event.kind == .ask && event.askStatus == .answered {
            if let waiter = pendingWaitersById.removeValue(forKey: event.id),
               let transcript = event.transcript, !transcript.isEmpty {
                waiter.resume(returning: transcript)
            }
        }
    }

    // MARK: - Read

    func list(limit: Int = 200) -> [ClientVoiceEvent] {
        Array(entries.prefix(max(1, limit)))
    }

    func pendingAskCount() -> Int {
        entries.filter { $0.kind == .ask && $0.askStatus == .pending }.count
    }

    // MARK: - Write

    func appendSpeak(text: String) -> ClientVoiceEvent {
        let event = ClientVoiceEvent(
            id: UUID(),
            kind: .speak,
            createdAt: Date(),
            text: text,
            prompt: nil,
            transcript: nil,
            draftTranscript: nil,
            askStatus: nil,
            answeredAt: nil
        )
        Task { await self.persistEvent(event) }
        return event
    }

    func appendAsk(prompt: String) -> ClientVoiceEvent {
        let event = ClientVoiceEvent(
            id: UUID(),
            kind: .ask,
            createdAt: Date(),
            text: nil,
            prompt: prompt,
            transcript: nil,
            draftTranscript: nil,
            askStatus: .pending,
            answeredAt: nil
        )
        Task { await self.persistEvent(event) }
        return event
    }

    func markPendingAsLost() -> Int {
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        let stale = entries.filter {
            $0.kind == .ask && $0.askStatus == .pending && $0.createdAt < cutoff
        }
        guard !stale.isEmpty else { return 0 }

        for var event in stale {
            event.askStatus = .lost
            event.draftTranscript = nil
            Task { await self.persistEvent(event) }
        }
        return stale.count
    }

    func draftForAsk(id: UUID) -> String? {
        guard let event = entries.first(where: { $0.id == id }) else { return nil }
        let value = (event.draftTranscript ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    func updateAskDraft(id: UUID, draft: String) {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard var event = entries.first(where: { $0.id == id }),
              event.kind == .ask, event.askStatus == .pending else { return }

        event.draftTranscript = trimmed
        Task { await self.persistEvent(event) }
    }

    func answerAsk(id: UUID, response: String) throws -> ClientVoiceEvent {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw NSError(domain: "ClientVoiceEventsRepository", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Transcript cannot be empty"])
        }
        guard var event = entries.first(where: { $0.id == id }) else {
            throw NSError(domain: "ClientVoiceEventsRepository", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Event not found"])
        }
        guard event.kind == .ask else {
            throw NSError(domain: "ClientVoiceEventsRepository", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Not an ask event"])
        }

        event.transcript = trimmed
        event.draftTranscript = nil
        event.askStatus = .answered
        event.answeredAt = Date()

        Task { await self.persistEvent(event) }

        if let waiter = pendingWaitersById.removeValue(forKey: id) {
            waiter.resume(returning: trimmed)
        }
        return event
    }

    func clearAll() {
        let waiters = pendingWaitersById
        pendingWaitersById.removeAll()
        waiters.values.forEach { $0.resume(throwing: CancellationError()) }

        // Delete all voice event docs from Firestore
        let currentEntries = entries
        Task {
            let firestore = Firestore.firestore()
            for event in currentEntries {
                let path = FirestoreCollections.VoiceEvents(self.profileID) + "/\(event.id.uuidString)"
                try? await firestore.document(path).delete()
            }
        }
    }

    func waitForAnswer(id: UUID) async throws -> String {
        if let existing = entries.first(where: { $0.id == id }),
           existing.kind == .ask, existing.askStatus == .answered,
           let transcript = existing.transcript, !transcript.isEmpty {
            return transcript
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pendingWaitersById[id] = continuation
            }
        } onCancel: {
            Task { await self.cancelWaiter(id: id) }
        }
    }

    func cancelWaiter(id: UUID) {
        pendingWaitersById.removeValue(forKey: id)?.resume(throwing: CancellationError())
    }

    // MARK: - Firestore persistence

    private func persistEvent(_ event: ClientVoiceEvent) async {
        let firestore = Firestore.firestore()
        let path = FirestoreCollections.VoiceEvents(profileID) + "/\(event.id.uuidString)"
        do {
            try await firestore.document(path).setData(event.toFirestoreData(), merge: true)
        } catch {
            logger.error("Failed to persist voice event \(event.id): \(error.localizedDescription)")
        }
    }
}

// MARK: - ClientVoiceEvent Firestore serialization

extension ClientVoiceEvent {
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "kind": kind.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: Date())
        ]
        if let text { data["text"] = text }
        if let prompt { data["prompt"] = prompt }
        if let transcript { data["transcript"] = transcript }
        if let draftTranscript { data["draftTranscript"] = draftTranscript }
        if let askStatus { data["askStatus"] = askStatus.rawValue }
        if let answeredAt { data["answeredAt"] = Timestamp(date: answeredAt) }
        return data
    }

    static func fromFirestoreData(_ data: [String: Any]) -> ClientVoiceEvent? {
        guard let idStr = data["id"] as? String,
              let id = UUID(uuidString: idStr),
              let kindStr = data["kind"] as? String,
              let kind = ClientVoiceEventKind(rawValue: kindStr) else { return nil }

        let createdAt: Date
        if let ts = data["createdAt"] as? Timestamp {
            createdAt = ts.dateValue()
        } else {
            createdAt = Date()
        }

        let answeredAt: Date?
        if let ts = data["answeredAt"] as? Timestamp {
            answeredAt = ts.dateValue()
        } else {
            answeredAt = nil
        }

        let askStatus = (data["askStatus"] as? String).flatMap { ClientVoiceAskStatus(rawValue: $0) }

        return ClientVoiceEvent(
            id: id,
            kind: kind,
            createdAt: createdAt,
            text: data["text"] as? String,
            prompt: data["prompt"] as? String,
            transcript: data["transcript"] as? String,
            draftTranscript: data["draftTranscript"] as? String,
            askStatus: askStatus,
            answeredAt: answeredAt
        )
    }
}
