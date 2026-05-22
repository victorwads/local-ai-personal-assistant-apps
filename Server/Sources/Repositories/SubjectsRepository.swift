import Foundation
import FirebaseFirestore
import os

enum SubjectsRepositoryError: LocalizedError {
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

actor SubjectsRepository {
    private let profileID: String
    private var entries: [SubjectEntry] = []
    private var listenerRegistration: ListenerRegistrationWrapper?
    private let logger = Logger(subsystem: "dev.wads.AssistantMCPServer", category: "SubjectsRepository")

    init(profileID: String) {
        self.profileID = profileID
    }

    func startListening() {
        let firestore = Firestore.firestore()
        let path = FirestoreCollections.Issues(profileID)
        
        let registration = firestore.collection(path).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let snapshot = snapshot else {
                if let error = error {
                    self.logger.error("Error listening to issues: \(error.localizedDescription)")
                }
                return
            }
            
            var newEntries: [SubjectEntry] = []
            for document in snapshot.documents {
                if let entry = SubjectEntry.fromFirestoreData(document.data()) {
                    newEntries.append(entry)
                }
            }
            
            Task {
                await self.updateEntries(newEntries)
            }
        }
        
        self.listenerRegistration = ListenerRegistrationWrapper(registration)
    }

    private func updateEntries(_ newEntries: [SubjectEntry]) {
        self.entries = newEntries
        NotificationCenter.default.post(name: .subjectsRepositoryDidChange, object: nil)
    }

    func listAll() -> [SubjectEntry] {
        entries.sorted { $0.updatedAt > $1.updatedAt }
    }

    func listActive() -> [SubjectEntry] {
        listAll().filter { $0.status == .active }
    }

    func get(id: UUID?) throws -> SubjectEntry {
        guard let id else {
            throw SubjectsRepositoryError.missingParameter("id")
        }
        guard let found = entries.first(where: { $0.id == id }) else {
            throw SubjectsRepositoryError.invalidParameter("Subject not found")
        }
        return found
    }

    func create(
        title: String?,
        summary: String?,
        initialRequest: String?,
        stopCondition: String?,
        details: String?,
        priority: Int?,
        participants: [String]?,
        nextSteps: [String]?,
        whatsappChatId: String?,
        gmailThreadId: String?,
        calendarEventId: String?
    ) async throws -> SubjectEntry {
        let trimmedTitle = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            throw SubjectsRepositoryError.missingParameter("title")
        }

        let trimmedSummary = (summary ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedSummary.isEmpty {
            throw SubjectsRepositoryError.missingParameter("summary")
        }

        let trimmedInitialRequest = (initialRequest ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedInitialRequest.isEmpty {
            throw SubjectsRepositoryError.missingParameter("initialRequest")
        }

        let trimmedStopCondition = (stopCondition ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedStopCondition.isEmpty {
            throw SubjectsRepositoryError.missingParameter("stopCondition")
        }

        let now = Date()
        let entry = SubjectEntry(
            id: UUID(),
            title: trimmedTitle,
            summary: trimmedSummary,
            initialRequest: trimmedInitialRequest,
            stopCondition: trimmedStopCondition,
            details: normalizedOptional(details),
            status: .active,
            priority: max(0, priority ?? 0),
            participants: (participants ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
            nextSteps: (nextSteps ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
            eventLog: [],
            whatsappChatId: normalizedOptional(whatsappChatId),
            whatsappAfterMessageId: nil,
            gmailThreadId: normalizedOptional(gmailThreadId),
            calendarEventId: normalizedOptional(calendarEventId),
            createdAt: now,
            updatedAt: now
        )
        
        try await persistEntry(entry)
        return entry
    }

    func update(
        id: UUID?,
        title: String?,
        summary: String?,
        stopCondition: String?,
        details: String?,
        priority: Int?,
        participants: [String]?,
        nextSteps: [String]?,
        appendUpdatesLog: [String]?,
        whatsappChatId: String?,
        whatsappAfterMessageId: String?,
        gmailThreadId: String?,
        calendarEventId: String?
    ) async throws -> SubjectEntry {
        guard let id else {
            throw SubjectsRepositoryError.missingParameter("id")
        }

        guard var subject = entries.first(where: { $0.id == id }) else {
            throw SubjectsRepositoryError.invalidParameter("Subject not found")
        }

        if let title {
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedTitle.isEmpty {
                subject.title = trimmedTitle
            }
        }
        if let summary {
            let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedSummary.isEmpty {
                subject.summary = trimmedSummary
            }
        }
        if let stopCondition {
            let trimmedStopCondition = stopCondition.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedStopCondition.isEmpty {
                subject.stopCondition = trimmedStopCondition
            }
        }
        if let details {
            let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
            subject.details = trimmed.isEmpty ? nil : trimmed
        }
        if let priority {
            subject.priority = max(0, priority)
        }
        if let participants {
            subject.participants = participants.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        if let nextSteps {
            subject.nextSteps = nextSteps.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        if let appendUpdatesLog {
            appendUpdates(appendUpdatesLog, to: &subject)
        }
        if let whatsappChatId {
            let trimmed = whatsappChatId.trimmingCharacters(in: .whitespacesAndNewlines)
            subject.whatsappChatId = trimmed.isEmpty ? nil : trimmed
        }
        if let whatsappAfterMessageId {
            let trimmed = whatsappAfterMessageId.trimmingCharacters(in: .whitespacesAndNewlines)
            subject.whatsappAfterMessageId = trimmed.isEmpty ? nil : trimmed
        }
        if let gmailThreadId {
            let trimmed = gmailThreadId.trimmingCharacters(in: .whitespacesAndNewlines)
            subject.gmailThreadId = trimmed.isEmpty ? nil : trimmed
        }
        if let calendarEventId {
            let trimmed = calendarEventId.trimmingCharacters(in: .whitespacesAndNewlines)
            subject.calendarEventId = trimmed.isEmpty ? nil : trimmed
        }

        subject.updatedAt = Date()
        try await persistEntry(subject)
        return subject
    }

    func resolve(id: UUID?, reason: String?) async throws -> SubjectEntry {
        try await close(
            id: id,
            status: .resolved,
            reason: reason
        )
    }

    func cancel(id: UUID?, reason: String?) async throws -> SubjectEntry {
        try await close(
            id: id,
            status: .canceled,
            reason: reason
        )
    }

    private func close(id: UUID?, status: SubjectStatus, reason: String?) async throws -> SubjectEntry {
        guard let id else {
            throw SubjectsRepositoryError.missingParameter("id")
        }

        let trimmedReason = (reason ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedReason.isEmpty {
            throw SubjectsRepositoryError.missingParameter("reason")
        }

        guard var subject = entries.first(where: { $0.id == id }) else {
            throw SubjectsRepositoryError.invalidParameter("Subject not found")
        }

        try applyTerminalStatus(&subject, status: status, reason: trimmedReason)
        try await persistEntry(subject)
        return subject
    }

    private func applyTerminalStatus(_ subject: inout SubjectEntry, status: SubjectStatus, reason: String?) throws {
        let trimmedReason = (reason ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedReason.isEmpty {
            throw SubjectsRepositoryError.missingParameter("reason")
        }

        subject.status = status
        let actionLabel: String = {
            switch status {
            case .resolved:
                return "resolved"
            case .canceled:
                return "canceled"
            case .active:
                return "updated"
            }
        }()
        subject.eventLog.append(
            EventEntry(
                timestamp: Date(),
                description: "Subject \(actionLabel). Reason: \(trimmedReason)",
                source: "manual"
            )
        )
        subject.updatedAt = Date()
    }

    private func appendUpdates(_ updates: [String], to subject: inout SubjectEntry) {
        var existingDescriptions = Set(subject.eventLog.map(\.description))

        for update in updates {
            let trimmed = update.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard !existingDescriptions.contains(trimmed) else { continue }

            subject.eventLog.append(
                EventEntry(
                    description: trimmed,
                    source: "assistant",
                    author: "assistant"
                )
            )
            existingDescriptions.insert(trimmed)
        }
    }

    private func normalizedOptional(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private func persistEntry(_ entry: SubjectEntry) async throws {
        let firestore = Firestore.firestore()
        let path = FirestoreCollections.Issues(profileID) + "/\(entry.id.uuidString)"
        try await firestore.document(path).setData(entry.toFirestoreData(), merge: true)
    }
}
