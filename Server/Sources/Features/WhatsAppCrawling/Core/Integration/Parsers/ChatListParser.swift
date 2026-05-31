import Foundation

protocol ChatListParser: CrawlingParser where Output == [CrawledChat] {}

struct ParsedChatHeader: Sendable {
    let id: String
    let title: String
    let lastMessagePreview: String?
    let lastMessageTimeText: String?
    let unreadCount: Int
    let stateHash: String
    let openChatElement: WebViewInteractiveElement?
}

enum WhatsAppChatListParser {
    static func parse(from rootObject: [String: Any]) -> [ParsedChatHeader] {
        guard
            let web = rootObject["web"] as? [String: Any],
            let roots = web["chatListRoot"] as? [Any]
        else {
            return []
        }

        var headers: [ParsedChatHeader] = []
        for root in roots {
            guard let rootObject = root as? [String: Any], let chatItems = rootObject["chatItems"] as? [Any] else { continue }
            for chatItem in chatItems {
                guard let chatObject = chatItem as? [String: Any] else { continue }
                let title = WhatsAppCrawlingNormalizer.normalizeText(chatObject["chatItemName"] as? String) ?? "Untitled"
                let lastMessagePreview = WhatsAppCrawlingNormalizer.normalizeText(chatObject["chatItemLastMessage"] as? String)
                let lastMessageTimeText = WhatsAppCrawlingNormalizer.normalizeText(chatObject["chatItemLastMessageTime"] as? String)
                let unreadCount = parseUnreadCount(from: chatObject["chatItemUnreadBadge"])

                let stateHash = WhatsAppCrawlingNormalizer.makeChatStateHash(
                    title: title,
                    lastMessagePreview: lastMessagePreview,
                    lastMessageTimeText: lastMessageTimeText,
                    unreadCount: unreadCount
                )
                headers.append(
                    ParsedChatHeader(
                        id: WhatsAppCrawlingNormalizer.makeWhatsAppChatId(title: title),
                        title: title,
                        lastMessagePreview: lastMessagePreview,
                        lastMessageTimeText: lastMessageTimeText,
                        unreadCount: unreadCount,
                        stateHash: stateHash,
                        openChatElement: WebViewInteractiveElementDetector.from(chatObject["chatClickableToOpenChat"] as Any)
                    )
                )
            }
        }

        return headers
    }

    private static func parseUnreadCount(from rawBadge: Any?) -> Int {
        guard let badge = rawBadge as? [String: Any] else { return 0 }
        if let count = badge["count"] as? Int { return max(0, count) }
        if let count = badge["count"] as? Double { return max(0, Int(count)) }
        if let countText = badge["count"] as? String, let count = Int(countText) { return max(0, count) }
        return 0
    }
}
