import Foundation

@MainActor
struct MCPServerContext {
    let runtime: any MCPServerRuntimeProviding
    let memoryStore: WhatsAppMemoryStore
    let accessibility: AccessibilityService
    let accessibilityScheduler: AccessibilityActionScheduler
    let parser: WhatsAppAppParser
    let interactor: WhatsAppInteractor
    let voiceAssistant: VoiceAssistant
    let nicknamesRepository: NicknamesRepository
    let memoriesRepository: MemoriesRepository
    let subjectsRepository: SubjectsRepository
    let clientVoiceEventsRepository: ClientVoiceEventsRepository
}

extension MCPServerContext {
    func assistantName() -> String {
        runtime.assistantName()
    }

    func speechLanguage() -> String {
        runtime.speechLanguage()
    }

    func speechVoiceIdentifier() -> String? {
        runtime.speechVoiceIdentifier()
    }

    func speechRate() -> Float {
        runtime.speechRate()
    }

    func formattedMCPSendMessages(for texts: [String]) -> [String] {
        runtime.formattedMCPSendMessages(for: texts)
    }

    func refreshPendingClientAskCount() async {
        await runtime.refreshPendingClientAskCount()
    }

    func beginClientPromptWait() async -> UUID {
        await runtime.beginClientPromptWait()
    }

    func endClientPromptWait(id: UUID) async {
        await runtime.endClientPromptWait(id: id)
    }

    func pendingClientPromptWaitCount() async -> Int {
        await runtime.pendingClientPromptWaitCount()
    }

    func submitClientPrompt(_ text: String) async {
        await runtime.submitClientPrompt(text)
    }

    func consumeClientPrompt() async -> String? {
        await runtime.consumeClientPrompt()
    }

    func sendMessageViaScheduler(_ text: String, _ conversationId: String) async throws {
        try await runtime.sendMessageViaScheduler(text, to: conversationId)
    }

    func sendMessagesViaScheduler(_ texts: [String], _ conversationId: String) async throws {
        try await runtime.sendMessagesViaScheduler(texts, to: conversationId)
    }

    func ensureChatLoaded(_ chatId: String, _ reason: String) async {
        await runtime.ensureChatLoaded(chatId: chatId, reason: reason)
    }

    func isBlocked(_ conversationName: String) -> Bool {
        runtime.isBlocked(conversationName)
    }

    func appendLog(_ message: String, level: LogLevel) {
        runtime.appendLog(message, level: level)
    }

    func conversationJSONValue(_ conversation: ConversationSummary) -> JSONValue {
        var payload: [String: JSONValue] = [
            "id": .string(conversation.id),
            "name": .string(conversation.name),
            "unreadCount": .number(Double(conversation.unreadCount)),
            "lastMessageDirection": .string(conversation.lastMessageDirection.mcpValue),
            "lastMessageStatus": .string(conversation.lastMessageStatus.rawValue),
            "isTyping": .bool(conversation.isTyping)
        ]

        if let lastMessagePreview = conversation.lastMessagePreview {
            payload["lastMessagePreview"] = .string(lastMessagePreview)
        }
        if let lastMessageAtText = conversation.lastMessageAtText {
            payload["lastMessageAtText"] = .string(lastMessageAtText)
        }

        return .object(payload)
    }

    func messageJSONValue(_ message: Message) -> JSONValue {
        var payload: [String: JSONValue] = [
            "id": .string(message.id),
            "direction": .string(message.direction.mcpValue),
            "kind": .string(message.kind.rawValue),
            "status": .string(message.status.rawValue),
            "rawAccessibilityText": .string(message.rawAccessibilityText),
            "isHandled": .bool(message.isHandled)
        ]

        if let text = message.text {
            payload["text"] = .string(text)
        }
        if let durationSeconds = message.durationSeconds {
            payload["durationSeconds"] = .number(durationSeconds)
        }
        if let timestamp = message.timestamp {
            payload["timestamp"] = .from(date: timestamp)
        }
        if let whatsappTimestampText = message.whatsappTimestampText {
            payload["whatsappTimestampText"] = .string(whatsappTimestampText)
        }

        return .object(payload)
    }

    func chatMessagesEventJSONValue(chat: ConversationSummary, messages: [Message]) -> JSONValue {
        .object([
            "type": .string("chat_messages"),
            "chat": conversationJSONValue(chat),
            "messages": .array(messages.map(messageJSONValue))
        ])
    }

    func memoryEntryJSONValue(_ entry: MemoryEntry) -> JSONValue {
        .object([
            "key": .string(entry.key),
            "content": .string(entry.content),
            "tags": .array(entry.tags.map(JSONValue.string))
        ])
    }

    func subjectEntryJSONValue(_ entry: SubjectEntry) -> JSONValue {
        var payload: [String: JSONValue] = [
            "id": .string(entry.id.uuidString),
            "title": .string(entry.title),
            "summary": .string(entry.summary),
            "initialRequest": .string(entry.initialRequest),
            "status": .string(entry.status.rawValue),
            "priority": .number(Double(entry.priority)),
            "participants": .array(entry.participants.map(JSONValue.string)),
            "nextSteps": .array(entry.nextSteps.map(JSONValue.string)),
            "updatesLog": .array(entry.eventLog.map { .string($0.description) }),
            "createdAt": .from(date: entry.createdAt)
        ]

        if let details = entry.details?.trimmingCharacters(in: .whitespacesAndNewlines), !details.isEmpty {
            payload["details"] = .string(details)
        }
        if let whatsappChatId = entry.whatsappChatId?.trimmingCharacters(in: .whitespacesAndNewlines), !whatsappChatId.isEmpty {
            payload["whatsappChatId"] = .string(whatsappChatId)
        }
        if let whatsappAfterMessageId = entry.whatsappAfterMessageId?.trimmingCharacters(in: .whitespacesAndNewlines), !whatsappAfterMessageId.isEmpty {
            payload["whatsappAfterMessageId"] = .string(whatsappAfterMessageId)
        }
        if let gmailThreadId = entry.gmailThreadId?.trimmingCharacters(in: .whitespacesAndNewlines), !gmailThreadId.isEmpty {
            payload["gmailThreadId"] = .string(gmailThreadId)
        }
        if let calendarEventId = entry.calendarEventId?.trimmingCharacters(in: .whitespacesAndNewlines), !calendarEventId.isEmpty {
            payload["calendarEventId"] = .string(calendarEventId)
        }

        return .object(payload)
    }

    func nicknameEntryJSONValue(_ entry: NicknameEntry) -> JSONValue {
        .object([
            "id": .string(entry.id.uuidString),
            "chatId": .string(entry.chatId),
            "chatName": .string(entry.chatName),
            "nickname": .string(entry.nickname)
        ])
    }

}

private extension MessageDirection {
    var mcpValue: String {
        switch self {
        case .outgoing:
            return "sent"
        case .incoming:
            return "received"
        case .unknown:
            return "unknown"
        }
    }
}
