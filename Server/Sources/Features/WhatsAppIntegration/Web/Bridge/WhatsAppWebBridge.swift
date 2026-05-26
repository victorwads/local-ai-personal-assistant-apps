import Foundation
import WebKit

enum WhatsAppWebBridgeError: LocalizedError {
    case unexpectedResponse
    case invalidSnapshotPayload
    case elementNotFound(String)
    case unsupportedOperation(String)

    var errorDescription: String? {
        switch self {
        case .unexpectedResponse:
            return "Unexpected JavaScript response from WhatsApp Web."
        case .invalidSnapshotPayload:
            return "Could not decode WhatsApp Web snapshot payload."
        case .elementNotFound(let details):
            return "Could not find the target element in WhatsApp Web. \(details)"
        case .unsupportedOperation(let details):
            return details
        }
    }
}

@MainActor
final class WhatsAppWebBridge {
    private let yamlExtractionRunner = WhatsAppWebYAMLExtractionRunner()
    private let chatListParser = WhatsAppWebChatListParser()

    func captureExtractionTree(from webView: WKWebView) async throws -> AnySendable {
        let tree = try loadWebSelectorTree()
        let result = try await yamlExtractionRunner.run(yamlTree: tree, webView: webView)
        return result.tree
    }

    func captureSnapshot(from webView: WKWebView) async throws -> WhatsAppWebPageSnapshot {
        let script = WhatsAppWebJavaScript.dumpDocumentScript
        let json = try await webView.evaluateJavaScriptString(script)

        guard let data = json.data(using: .utf8) else {
            throw WhatsAppWebBridgeError.invalidSnapshotPayload
        }

        struct RawSnapshotPayload: Codable {
            let url: String
            let title: String
            let documentReadyState: String
            let rawHTML: String
            let capturedAt: Date
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(RawSnapshotPayload.self, from: data)
            let rawHTML = payload.rawHTML
            return WhatsAppWebPageSnapshot(
                url: payload.url,
                title: payload.title,
                documentReadyState: payload.documentReadyState,
                rawHTML: rawHTML,
                isLoggedIn: true,
                hasQrCanvas: false,
                chatRowCount: 0,
                unreadBadgeCount: 0,
                selectedChatTitle: nil,
                composePlaceholder: nil,
                bodyTextSample: String(rawHTML.prefix(500)),
                flow: .unknown,
                capturedAt: payload.capturedAt
            )
        } catch {
            throw WhatsAppWebBridgeError.invalidSnapshotPayload
        }
    }

    func captureSelectedChat(from webView: WKWebView, limit: Int) async throws -> WhatsAppWebChatCapture {
        throw WhatsAppWebBridgeError.unsupportedOperation("captureSelectedChat has been removed from the legacy WebView bridge.")
    }

    func listChatTitles(from webView: WKWebView, limit: Int) async throws -> [WhatsAppWebChatListItem] {
        let items = chatListParser.parseItems(from: try await captureExtractionTree(from: webView))
        return Array(items.prefix(max(1, min(limit, 200))))
    }

    func openChatByTitle(from webView: WKWebView, title: String) async throws {
        throw WhatsAppWebBridgeError.unsupportedOperation("openChatByTitle has been removed from the legacy WebView bridge.")
    }

    private func loadWebSelectorTree() throws -> YAMLTree {
        guard let url = Bundle.main.url(forResource: "whatsapp_web_selectors", withExtension: "yaml"),
              let data = try? Data(contentsOf: url),
              let yaml = String(data: data, encoding: .utf8) else {
            throw WhatsAppWebBridgeError.unexpectedResponse
        }

        return try YAMLTree.parse(yaml: yaml)
    }

    private func loadWebActionShortcuts() throws -> WhatsAppWebActionShortcuts {
        return WhatsAppWebActionShortcuts.from(yamlTree: try loadWebSelectorTree())
    }

    func executeShortcut(from webView: WKWebView, modifiers: [String], key: String) async throws {
        let modifiersJSON = try AnySendableJSON.encodeToJSONString(.array(modifiers.map { .string($0) }))
        let script = WhatsAppWebJavaScript.makeShortcutScript(
            modifiersJSONLiteral: modifiersJSON,
            keyJSONLiteral: Self.javascriptStringLiteral(key)
        )
        _ = try await webView.evaluateJavaScriptString(script)
    }

    func archiveConversation(from webView: WKWebView) async throws {
        let shortcuts = try loadWebActionShortcuts()
        guard let shortcut = shortcuts.archiveConversation else {
            throw WhatsAppWebBridgeError.unexpectedResponse
        }
        try await executeShortcut(from: webView, modifiers: shortcut.modifiers, key: shortcut.key)
    }

    func openSearch(from webView: WKWebView) async throws {
        let shortcuts = try loadWebActionShortcuts()
        guard let shortcut = shortcuts.search else {
            throw WhatsAppWebBridgeError.unexpectedResponse
        }
        try await executeShortcut(from: webView, modifiers: shortcut.modifiers, key: shortcut.key)
    }

    func captureDebugDOM(from webView: WKWebView) async throws -> WhatsAppWebDebugDOMSnapshot {
        throw WhatsAppWebBridgeError.unsupportedOperation("captureDebugDOM has been removed from the legacy WebView bridge.")
    }

    struct MessageSendResult: Codable, Equatable {
        let result: String
        let composerFound: Bool
        let inserted: Bool
        let composerSelector: String?
        let currentText: String?
        let composeDraftText: String?
        let observedOutgoingText: String?
        let selectedChatTitle: String?
        let sendButtonFound: Bool?
        let sendButtonClicked: Bool?
        let activeElementTag: String?
    }

    func sendMessage(from webView: WKWebView, text: String) async throws -> MessageSendResult {
        throw WhatsAppWebBridgeError.unsupportedOperation("sendMessage has been removed from the legacy WebView bridge.")
    }

    private static func javascriptStringLiteral(_ value: String) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let json = String(data: data, encoding: .utf8) else {
            return "\"\""
        }
        return json
    }
}

@MainActor
private extension WKWebView {
    func evaluateJavaScriptString(_ javaScript: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            evaluateJavaScript(javaScript) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let stringResult = result as? String {
                    continuation.resume(returning: stringResult)
                } else {
                    continuation.resume(throwing: WhatsAppWebBridgeError.unexpectedResponse)
                }
            }
        }
    }
}
