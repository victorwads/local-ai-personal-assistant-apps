import Foundation

@MainActor
struct WhatsAppNativeChatListParser: WhatsAppChatListParser {
    func verify(context: WhatsAppIntegrationContext) throws {
        guard context.mode == .desktopAX else {
            throw AccessibilityError.nodeNotFound
        }
        guard let extractionTree = context.extractionTree,
              chatListFound(in: extractionTree) else {
            throw AccessibilityError.nodeNotFound
        }
    }

    func parse(context: WhatsAppIntegrationContext) throws -> [ConversationSummary] {
        try verify(context: context)
        guard let extractionTree = context.extractionTree,
              let items = chatItems(in: extractionTree) else {
            return []
        }

        var seen = Set<String>()
        return items.compactMap { item in
            guard let itemDict = objectValue(of: item),
                  let extract = objectValue(of: itemDict["extract"] ?? .null),
                  let name = stringValue(at: ["title", "value"], in: extract)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty,
                  !seen.contains(name) else {
                return nil
            }
            seen.insert(name)

            let preview = stringValue(at: ["preview", "value"], in: extract)
            let timeText = stringValue(at: ["time_text", "value"], in: extract)
            let unreadCount = intValue(at: ["unread_count", "value"], in: extract) ?? 0
            let path = stringValue(at: ["path"], in: itemDict)
            let accessibilityPath = path?.split(separator: ".").compactMap { Int($0) } ?? []

            return ConversationSummary(
                id: name,
                accessibilityPath: accessibilityPath,
                name: name,
                unreadCount: unreadCount,
                isPinned: false,
                isSelected: false,
                lastMessagePreview: preview,
                lastMessageAtText: timeText,
                lastMessageDirection: .unknown,
                lastMessageStatus: .unknown,
                isTyping: false
            )
        }
    }

    private func chatListFound(in tree: AnySendable) -> Bool {
        guard let native = objectValue(of: tree)?["native"],
              let chatListRoot = objectValue(of: native)?["chat_list_root"],
              let found = boolValue(at: ["found"], in: objectValue(of: chatListRoot) ?? [:]) else {
            return false
        }
        return found
    }

    private func chatItems(in tree: AnySendable) -> [AnySendable]? {
        guard let native = objectValue(of: tree)?["native"],
              let chatListRoot = objectValue(of: native)?["chat_list_root"],
              let extract = objectValue(of: chatListRoot)?["extract"],
              let chatItems = objectValue(of: extract)?["chat_items"],
              let items = objectValue(of: chatItems)?["items"].flatMap(arrayValue(of:)),
              !items.isEmpty else {
            return nil
        }
        return items
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
