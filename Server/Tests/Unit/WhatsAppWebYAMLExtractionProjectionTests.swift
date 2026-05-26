import XCTest

@testable import AssistantMCPServer

final class WhatsAppWebYAMLExtractionProjectionTests: XCTestCase {
    func test_projectedSpec_keepsOnlyFlowsAndWebSections() {
        let root: [String: AnySendable] = [
            "schema_version": .int(1),
            "version": .string("2026-05-22"),
            "actions": .object([
                "shortcuts": .object([
                    "search": .object([
                        "key": .string("/")
                    ])
                ])
            ]),
            "flows": .object([
                "chat_list": .object([
                    "type": .string("flow")
                ])
            ]),
            "web": .object([
                "chat_list_root": .object([
                    "type": .string("element")
                ])
            ])
        ]

        let projected = WhatsAppWebYAMLExtractionProjection.projectedSpec(fromRoot: root)

        XCTAssertEqual(
            projected,
            .object([
                "flows": .object([
                    "chat_list": .object([
                        "type": .string("flow")
                    ])
                ]),
                "web": .object([
                    "chat_list_root": .object([
                        "type": .string("element")
                    ])
                ])
            ])
        )
    }

    func test_extractedTree_unwrapsTreePayload() throws {
        let payload: AnySendable = .object([
            "result": .string("ok"),
            "tree": .object([
                "web": .object([
                    "chat_list_root": .object([
                        "found": .bool(true)
                    ])
                ])
            ])
        ])

        let extracted = try WhatsAppWebYAMLExtractionProjection.extractedTree(from: payload)

        XCTAssertEqual(
            extracted,
            .object([
                "web": .object([
                    "chat_list_root": .object([
                        "found": .bool(true)
                    ])
                ])
            ])
        )
    }
}
