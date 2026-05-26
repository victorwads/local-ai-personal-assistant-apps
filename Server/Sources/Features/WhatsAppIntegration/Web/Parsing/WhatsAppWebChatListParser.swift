import Foundation

struct WhatsAppWebChatListItem: Sendable, Equatable {
    let title: String
    let preview: String?
    let timeText: String?
    let unreadCount: Int
    let path: String?
    let clickablePath: String?
}

@MainActor
struct WhatsAppWebChatListParser: WhatsAppChatListParser {
    func verify(context: WhatsAppIntegrationContext) throws {
        guard context.mode == .web else {
            throw WhatsAppWebBridgeError.unexpectedResponse
        }
        guard let extractionTree = context.extractionTree,
              chatListFound(in: extractionTree) else {
            throw WhatsAppWebBridgeError.elementNotFound("Web chat list root was not found in extraction tree.")
        }
    }

    func parse(context: WhatsAppIntegrationContext) throws -> [ConversationSummary] {
        try verify(context: context)
        guard let extractionTree = context.extractionTree else {
            return []
        }

        return parseItems(from: extractionTree).map { item in
            ConversationSummary(
                id: item.title,
                accessibilityPath: [],
                name: item.title,
                unreadCount: item.unreadCount,
                isPinned: false,
                isSelected: false,
                lastMessagePreview: item.preview,
                lastMessageAtText: item.timeText,
                lastMessageDirection: .unknown,
                lastMessageStatus: .unknown,
                isTyping: false
            )
        }
    }

    func parseItems(from tree: AnySendable) -> [WhatsAppWebChatListItem] {
        guard let items = chatItems(in: tree), !items.isEmpty else {
            return []
        }

        return items.compactMap(parseItem(_:))
    }

    private func chatListFound(in tree: AnySendable) -> Bool {
        guard let web = objectValue(of: tree)?["web"],
              let chatListRoot = objectValue(of: web)?["chat_list_root"],
              let found = boolValue(at: ["found"], in: objectValue(of: chatListRoot) ?? [:]) else {
            return false
        }
        return found
    }

    private func chatItems(in tree: AnySendable) -> [AnySendable]? {
        guard let web = objectValue(of: tree)?["web"],
              let chatListRoot = objectValue(of: web)?["chat_list_root"],
              let chatListExtract = objectValue(of: chatListRoot)?["extract"],
              let chatItemNode = objectValue(of: chatListExtract)?["chat_item"],
              let items = objectValue(of: chatItemNode)?["items"].flatMap(arrayValue(of:)),
              !items.isEmpty else {
            return nil
        }

        return items
    }

    private func parseItem(_ item: AnySendable) -> WhatsAppWebChatListItem? {
        guard let itemDict = objectValue(of: item),
              let extract = objectValue(of: itemDict["extract"] ?? .null) else {
            return nil
        }

        let title = stringValue(at: ["chat_item_name", "value"], in: extract)
            ?? stringValue(at: ["chat_item_name"], in: extract)
        let normalizedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let normalizedTitle, !normalizedTitle.isEmpty else {
            return nil
        }

        let preview = stringValue(at: ["chat_item_last_message", "value"], in: extract)
            ?? stringValue(at: ["chat_item_last_message"], in: extract)

        let timeText = stringValue(at: ["chat_item_last_message_time", "value"], in: extract)
            ?? stringValue(at: ["chat_item_last_message_time"], in: extract)

        let unreadCount = intValue(at: ["chat_item_unread_badge", "extract", "count", "value"], in: extract)
            ?? intValue(at: ["chat_item_unread_badge", "extract", "count"], in: extract)
            ?? 0

        let path = stringValue(at: ["path"], in: itemDict)
        let clickablePath = stringValue(at: ["extract", "chat_clickable_to_open_chat", "path"], in: itemDict)

        return WhatsAppWebChatListItem(
            title: normalizedTitle,
            preview: preview,
            timeText: timeText,
            unreadCount: unreadCount,
            path: path,
            clickablePath: clickablePath
        )
    }

    private func objectValue(of any: AnySendable?) -> [String: AnySendable]? {
        guard let any, case .object(let dict) = any else { return nil }
        return dict
    }

    private func arrayValue(of any: AnySendable?) -> [AnySendable]? {
        guard let any, case .array(let values) = any else { return nil }
        return values
    }

    private func stringValue(at path: [String], in root: [String: AnySendable]) -> String? {
        guard let value = value(at: path, in: root),
              case .string(let string) = value else {
            return nil
        }
        return string
    }

    private func intValue(at path: [String], in root: [String: AnySendable]) -> Int? {
        guard let value = value(at: path, in: root) else { return nil }
        switch value {
        case .int(let int):
            return int
        case .double(let double):
            return Int(double)
        default:
            return nil
        }
    }

    private func boolValue(at path: [String], in root: [String: AnySendable]) -> Bool? {
        guard let value = value(at: path, in: root),
              case .bool(let bool) = value else {
            return nil
        }
        return bool
    }

    private func value(at path: [String], in root: [String: AnySendable]) -> AnySendable? {
        var current: AnySendable? = .object(root)
        for key in path {
            guard let object = objectValue(of: current),
                  let next = object[key] else {
                return nil
            }
            current = next
        }
        return current
    }
}
