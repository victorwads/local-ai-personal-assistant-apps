import Foundation
import FirebaseFirestore

struct ConversationSummary: Identifiable, Codable, Equatable {
    let id: String
    let accessibilityPath: [Int]
    let name: String
    let unreadCount: Int
    let isPinned: Bool
    let isSelected: Bool
    let lastMessagePreview: String?
    let lastMessageAtText: String?
    let lastMessageDirection: MessageDirection
    let lastMessageStatus: MessageStatus
    let isTyping: Bool

    func replacing(id: String) -> ConversationSummary {
        ConversationSummary(
            id: id,
            accessibilityPath: accessibilityPath,
            name: name,
            unreadCount: unreadCount,
            isPinned: isPinned,
            isSelected: isSelected,
            lastMessagePreview: lastMessagePreview,
            lastMessageAtText: lastMessageAtText,
            lastMessageDirection: lastMessageDirection,
            lastMessageStatus: lastMessageStatus,
            isTyping: isTyping
        )
    }

    var listSignature: String {
        [
            name,
            lastMessagePreview ?? "",
            lastMessageAtText ?? "",
            "\(unreadCount)",
            lastMessageDirection.rawValue,
//            lastMessageStatus.rawValue
        ].joined(separator: "|")
    }
}

extension ConversationSummary {
    static func fromFirestoreData(_ data: [String: Any]) -> ConversationSummary? {
        guard let id = data["id"] as? String,
              let accessibilityPath = data["accessibilityPath"] as? [Int],
              let name = data["name"] as? String else {
            return nil
        }
        
        let unreadCount = data["unreadCount"] as? Int ?? 0
        let isPinned = data["isPinned"] as? Bool ?? false
        let isSelected = data["isSelected"] as? Bool ?? false
        let lastMessagePreview = data["lastMessagePreview"] as? String
        let lastMessageAtText = data["lastMessageAtText"] as? String
        
        let lastMessageDirection: MessageDirection
        if let dirStr = data["lastMessageDirection"] as? String {
            lastMessageDirection = MessageDirection(rawValue: dirStr) ?? .unknown
        } else {
            lastMessageDirection = .unknown
        }
        
        let lastMessageStatus: MessageStatus
        if let statusStr = data["lastMessageStatus"] as? String {
            lastMessageStatus = MessageStatus(rawValue: statusStr) ?? .unknown
        } else {
            lastMessageStatus = .unknown
        }
        
        let isTyping = data["isTyping"] as? Bool ?? false
        
        return ConversationSummary(
            id: id,
            accessibilityPath: accessibilityPath,
            name: name,
            unreadCount: unreadCount,
            isPinned: isPinned,
            isSelected: isSelected,
            lastMessagePreview: lastMessagePreview,
            lastMessageAtText: lastMessageAtText,
            lastMessageDirection: lastMessageDirection,
            lastMessageStatus: lastMessageStatus,
            isTyping: isTyping
        )
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "accessibilityPath": accessibilityPath,
            "name": name,
            "unreadCount": unreadCount,
            "isPinned": isPinned,
            "isSelected": isSelected,
            "lastMessagePreview": lastMessagePreview as Any,
            "lastMessageAtText": lastMessageAtText as Any,
            "lastMessageDirection": lastMessageDirection.rawValue,
            "lastMessageStatus": lastMessageStatus.rawValue,
            "isTyping": isTyping
        ]
    }
}

