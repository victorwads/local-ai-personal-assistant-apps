import Foundation
import FirebaseFirestore

enum MessageDirection: String, Codable, Equatable {
    case incoming
    case outgoing
    case unknown
}

enum MessageKind: String, Codable, Equatable {
    case text
    case voice
    case image
    case document
    case deleted
    case unknown
}

enum MessageStatus: String, Codable, Equatable {
    case sent
    case delivered
    case read
    case unknown
}

enum MessageOrigin: String, Codable, Equatable {
    /// Sent by the MCP assistant (i.e. through `send_message`).
    case assistant
    /// Sent by a human (the user) on this machine/account.
    case human
    /// Unknown or not inferred.
    case unknown
}

struct Message: Identifiable, Codable, Equatable {
    let id: String
    let chatId: String
    let direction: MessageDirection
    let kind: MessageKind
    /// Parsed sender name when available (primarily for incoming group messages).
    let authorName: String?
    /// Best-effort origin for outgoing messages (assistant vs human).
    let origin: MessageOrigin
    let text: String?
    let durationSeconds: Double?
    let timestamp: Date?
    let status: MessageStatus
    let rawAccessibilityText: String
    let whatsappTimestampText: String?
    let ingestedAt: Date?
    let handledAt: Date?

    init(
        id: String,
        chatId: String,
        direction: MessageDirection,
        kind: MessageKind,
        authorName: String? = nil,
        origin: MessageOrigin = .unknown,
        text: String?,
        durationSeconds: Double?,
        timestamp: Date?,
        status: MessageStatus,
        rawAccessibilityText: String,
        whatsappTimestampText: String? = nil,
        ingestedAt: Date? = nil,
        handledAt: Date? = nil
    ) {
        self.id = id
        self.chatId = chatId
        self.direction = direction
        self.kind = kind
        self.authorName = authorName
        self.origin = origin
        self.text = text
        self.durationSeconds = durationSeconds
        self.timestamp = timestamp
        self.status = status
        self.rawAccessibilityText = rawAccessibilityText
        self.whatsappTimestampText = whatsappTimestampText
        self.ingestedAt = ingestedAt
        self.handledAt = handledAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case chatId
        case direction
        case kind
        case authorName
        case origin
        case text
        case durationSeconds
        case timestamp
        case status
        case rawAccessibilityText
        case whatsappTimestampText
        case ingestedAt
        case handledAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        chatId = try container.decode(String.self, forKey: .chatId)
        direction = try container.decode(MessageDirection.self, forKey: .direction)
        kind = try container.decode(MessageKind.self, forKey: .kind)
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        origin = (try? container.decode(MessageOrigin.self, forKey: .origin)) ?? .unknown
        text = try container.decodeIfPresent(String.self, forKey: .text)
        durationSeconds = try container.decodeIfPresent(Double.self, forKey: .durationSeconds)
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp)
        status = (try? container.decode(MessageStatus.self, forKey: .status)) ?? .unknown
        rawAccessibilityText = (try? container.decode(String.self, forKey: .rawAccessibilityText)) ?? ""
        whatsappTimestampText = try container.decodeIfPresent(String.self, forKey: .whatsappTimestampText)
        ingestedAt = try container.decodeIfPresent(Date.self, forKey: .ingestedAt)
        handledAt = try container.decodeIfPresent(Date.self, forKey: .handledAt)
    }

    var isHandled: Bool {
        handledAt != nil
    }
}

extension Message {
    var semanticDeduplicationKey: String {
        let normalizedText = Message.normalizedDeduplicationText(text ?? rawAccessibilityText)
        let timestampKey = Message.normalizedDeduplicationText(
            whatsappTimestampText ?? timestamp.map { ISO8601DateFormatter().string(from: $0) } ?? ""
        )

        return [
            chatId,
            direction.rawValue,
            kind.rawValue,
            normalizedText,
            timestampKey
        ].joined(separator: "|")
    }

    func replacing(
        id: String? = nil,
        chatId: String? = nil,
        authorName: String?? = nil,
        origin: MessageOrigin? = nil,
        text: String? = nil,
        durationSeconds: Double?? = nil,
        timestamp: Date?? = nil,
        status: MessageStatus? = nil,
        rawAccessibilityText: String? = nil,
        whatsappTimestampText: String?? = nil,
        ingestedAt: Date?? = nil,
        handledAt: Date?? = nil
    ) -> Message {
        Message(
            id: id ?? self.id,
            chatId: chatId ?? self.chatId,
            direction: direction,
            kind: kind,
            authorName: authorName ?? self.authorName,
            origin: origin ?? self.origin,
            text: text ?? self.text,
            durationSeconds: durationSeconds ?? self.durationSeconds,
            timestamp: timestamp ?? self.timestamp,
            status: status ?? self.status,
            rawAccessibilityText: rawAccessibilityText ?? self.rawAccessibilityText,
            whatsappTimestampText: whatsappTimestampText ?? self.whatsappTimestampText,
            ingestedAt: ingestedAt ?? self.ingestedAt,
            handledAt: handledAt ?? self.handledAt
        )
    }

    private static func normalizedDeduplicationText(_ value: String) -> String {
        value
            .normalizedAXText
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}

extension Message {
    static func fromFirestoreData(_ data: [String: Any]) -> Message? {
        guard let id = data["id"] as? String,
              let chatId = data["chatId"] as? String else {
            return nil
        }
        
        let direction: MessageDirection
        if let dirStr = data["direction"] as? String {
            direction = MessageDirection(rawValue: dirStr) ?? .unknown
        } else {
            direction = .unknown
        }
        
        let kind: MessageKind
        if let kindStr = data["kind"] as? String {
            kind = MessageKind(rawValue: kindStr) ?? .unknown
        } else {
            kind = .unknown
        }
        
        let authorName = data["authorName"] as? String
        
        let origin: MessageOrigin
        if let origStr = data["origin"] as? String {
            origin = MessageOrigin(rawValue: origStr) ?? .unknown
        } else {
            origin = .unknown
        }
        
        let text = data["text"] as? String
        let durationSeconds = data["durationSeconds"] as? Double
        
        let timestamp: Date?
        if let ts = data["timestamp"] as? Timestamp {
            timestamp = ts.dateValue()
        } else if let tsString = data["timestamp"] as? String, let date = ISO8601DateFormatter().date(from: tsString) {
            timestamp = date
        } else {
            timestamp = nil
        }
        
        let status: MessageStatus
        if let statusStr = data["status"] as? String {
            status = MessageStatus(rawValue: statusStr) ?? .unknown
        } else {
            status = .unknown
        }
        
        let rawAccessibilityText = data["rawAccessibilityText"] as? String ?? ""
        let whatsappTimestampText = data["whatsappTimestampText"] as? String
        
        let ingestedAt: Date?
        if let ts = data["ingestedAt"] as? Timestamp {
            ingestedAt = ts.dateValue()
        } else if let tsString = data["ingestedAt"] as? String, let date = ISO8601DateFormatter().date(from: tsString) {
            ingestedAt = date
        } else {
            ingestedAt = nil
        }
        
        let handledAt: Date?
        if let ts = data["handledAt"] as? Timestamp {
            handledAt = ts.dateValue()
        } else if let tsString = data["handledAt"] as? String, let date = ISO8601DateFormatter().date(from: tsString) {
            handledAt = date
        } else {
            handledAt = nil
        }
        
        return Message(
            id: id,
            chatId: chatId,
            direction: direction,
            kind: kind,
            authorName: authorName,
            origin: origin,
            text: text,
            durationSeconds: durationSeconds,
            timestamp: timestamp,
            status: status,
            rawAccessibilityText: rawAccessibilityText,
            whatsappTimestampText: whatsappTimestampText,
            ingestedAt: ingestedAt,
            handledAt: handledAt
        )
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "chatId": chatId,
            "direction": direction.rawValue,
            "kind": kind.rawValue,
            "authorName": authorName as Any,
            "origin": origin.rawValue,
            "text": text as Any,
            "durationSeconds": durationSeconds as Any,
            "timestamp": timestamp != nil ? Timestamp(date: timestamp!) : Any?.none as Any,
            "status": status.rawValue,
            "rawAccessibilityText": rawAccessibilityText,
            "whatsappTimestampText": whatsappTimestampText as Any,
            "ingestedAt": ingestedAt != nil ? Timestamp(date: ingestedAt!) : Any?.none as Any,
            "handledAt": handledAt != nil ? Timestamp(date: handledAt!) : Any?.none as Any
        ]
    }
}

