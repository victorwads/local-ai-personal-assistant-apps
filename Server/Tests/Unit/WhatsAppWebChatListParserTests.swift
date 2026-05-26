import XCTest

@testable import AssistantMCPServer

final class WhatsAppWebChatListParserTests: XCTestCase {
    func test_parse_returnsChatListItemsFromWebExtractionTree() {
        let parser = WhatsAppWebChatListParser()
        let tree = makeChatListTree()

        let items = parser.parse(from: tree)

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].title, "Alice")
        XCTAssertEqual(items[0].preview, "Oi")
        XCTAssertEqual(items[0].timeText, "09:31")
        XCTAssertEqual(items[0].unreadCount, 3)
        XCTAssertEqual(items[0].path, "root.web.chat_list_root.extract.chat_item.items[0]")
        XCTAssertEqual(items[0].clickablePath, "0.1.2")

        XCTAssertEqual(items[1].title, "Grupo da família")
        XCTAssertNil(items[1].preview)
        XCTAssertNil(items[1].timeText)
        XCTAssertEqual(items[1].unreadCount, 0)
    }

    func test_parse_returnsEmptyWhenChatListIsMissing() {
        let parser = WhatsAppWebChatListParser()

        XCTAssertTrue(parser.parse(from: .object(["web": .object([:])])).isEmpty)
    }

    private func makeChatListTree() -> AnySendable {
        .object([
            "web": .object([
                "chat_list_root": .object([
                    "extract": .object([
                        "chat_item": .object([
                            "items": .array([
                                .object([
                                    "path": .string("root.web.chat_list_root.extract.chat_item.items[0]"),
                                    "extract": .object([
                                        "chat_item_name": .object([
                                            "value": .string("Alice")
                                        ]),
                                        "chat_item_last_message": .object([
                                            "value": .string("Oi")
                                        ]),
                                        "chat_item_last_message_time": .object([
                                            "value": .string("09:31")
                                        ]),
                                        "chat_item_unread_badge": .object([
                                            "extract": .object([
                                                "count": .object([
                                                    "value": .int(3)
                                                ])
                                            ])
                                        ]),
                                        "chat_clickable_to_open_chat": .object([
                                            "path": .string("0.1.2")
                                        ])
                                    ])
                                ]),
                                .object([
                                    "path": .string("root.web.chat_list_root.extract.chat_item.items[1]"),
                                    "extract": .object([
                                        "chat_item_name": .object([
                                            "value": .string("Grupo da família")
                                        ]),
                                        "chat_item_unread_badge": .object([
                                            "extract": .object([
                                                "count": .object([
                                                    "value": .int(0)
                                                ])
                                            ])
                                        ])
                                    ])
                                ])
                            ])
                        ])
                    ])
                ])
            ])
        ])
    }
}
