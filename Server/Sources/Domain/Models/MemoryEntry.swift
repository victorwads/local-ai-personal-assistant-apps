import Foundation
import FirebaseFirestore

struct MemoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    var key: String
    var content: String
    let createdAt: Date
    var updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case key
        case title
        case content
        case createdAt
        case updatedAt
    }

    init(
        id: UUID,
        key: String,
        content: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.key = key
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let decodedKey = try container.decodeIfPresent(String.self, forKey: .key)
            ?? container.decodeIfPresent(String.self, forKey: .title)
            ?? ""
        key = decodedKey.trimmingCharacters(in: .whitespacesAndNewlines)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(key, forKey: .key)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

extension MemoryEntry {
    static func fromFirestoreData(_ data: [String: Any]) -> MemoryEntry? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let key = data["key"] as? String,
              let content = data["content"] as? String else {
            return nil
        }
        
        let createdAt: Date
        if let ts = data["createdAt"] as? Timestamp {
            createdAt = ts.dateValue()
        } else if let tsString = data["createdAt"] as? String, let date = ISO8601DateFormatter().date(from: tsString) {
            createdAt = date
        } else {
            createdAt = Date()
        }
        
        let updatedAt: Date
        if let ts = data["updatedAt"] as? Timestamp {
            updatedAt = ts.dateValue()
        } else if let tsString = data["updatedAt"] as? String, let date = ISO8601DateFormatter().date(from: tsString) {
            updatedAt = date
        } else {
            updatedAt = createdAt
        }
        
        return MemoryEntry(id: id, key: key, content: content, createdAt: createdAt, updatedAt: updatedAt)
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id.uuidString,
            "key": key,
            "content": content,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
}

