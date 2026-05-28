import Foundation
import WebKit

@MainActor
final class WebViewElementInteractor {
    private struct InteractionCommand: Encodable {
        let id: String
        let action: String
        let payload: [String: String]?
    }

    let webView: WKWebView

    init(webView: WKWebView) {
        self.webView = webView
    }

    func click(_ element: WebViewInteractiveElement) async throws -> Bool {
        try await interact(with: element.id, action: "click", payload: nil)
    }

    func focus(_ element: WebViewInteractiveElement) async throws -> Bool {
        try await interact(with: element.id, action: "focus", payload: nil)
    }

    func type(_ text: String, into element: WebViewInteractiveElement) async throws -> Bool {
        try await interact(with: element.id, action: "type", payload: ["text": text])
    }

    func pressEnter(_ element: WebViewInteractiveElement) async throws -> Bool {
        try await interact(with: element.id, action: "pressEnter", payload: nil)
    }

    private func interact(with id: String, action: String, payload: [String: String]?) async throws -> Bool {
        let command = InteractionCommand(id: id, action: action, payload: payload)
        let commandData = try JSONEncoder().encode(command)
        guard let commandJSON = String(data: commandData, encoding: .utf8) else {
            return false
        }

        let script = """
        window.AssistantMCP.interactWithElementCommand(\(commandJSON));
        """

        let value = try await evaluate(script: script)
        return value as? Bool ?? false
    }

    private func evaluate(script: String) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            webView.evaluateJavaScript(script) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: result)
            }
        }
    }
}
