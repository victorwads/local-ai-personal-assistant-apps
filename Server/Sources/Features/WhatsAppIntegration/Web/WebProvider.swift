import Foundation
import WebKit

@MainActor
final class WebProvider: WhatsAppIntegrationProvider {
    let kind: WhatsAppIntegrationMode = .web

    let parser: WhatsAppConversationParser
    let interactor: WhatsAppConversationInteractor

    init(
        accountId: UUID,
        accounts: @escaping () -> [WhatsAppWebAccount],
        sessionStore: WhatsAppWebSessionStore,
        bridge: WhatsAppWebBridge,
        messageSettleDelayMilliseconds: Double
    ) {
        self.parser = WebParser(
            accountId: accountId,
            accounts: accounts,
            sessionStore: sessionStore,
            bridge: bridge,
            messageSettleDelayMilliseconds: messageSettleDelayMilliseconds
        )
        self.interactor = WebInteractor(accountId: accountId, accounts: accounts, sessionStore: sessionStore, bridge: bridge)
    }
}

@MainActor
private struct WebParser: WhatsAppConversationParser {
    let accountId: UUID
    let accounts: () -> [WhatsAppWebAccount]
    let sessionStore: WhatsAppWebSessionStore
    let bridge: WhatsAppWebBridge
    let messageSettleDelayMilliseconds: Double
    private let chatListParser = WhatsAppWebChatListParser()

    func listConversations() async throws -> [ConversationSummary] {
        guard let account = accounts().first(where: { $0.id == accountId }) else {
            return []
        }
        let webView = sessionStore.webView(for: account)
        let extractionTree = try await bridge.captureExtractionTree(from: webView)
        let context = WhatsAppIntegrationContext(
            mode: .web,
            flow: "chatList",
            extractionTree: extractionTree
        )
        return try chatListParser.parse(context: context)
    }

    func readMessages(limit: Int) async throws -> (selectedChatName: String?, flow: String?, messages: [Message], composeFocused: Bool, canSendText: Bool) {
        _ = limit
        // Intentionally inert until the Web message parser phase is restored.
        return (nil, nil, [], false, false)
    }
}

@MainActor
private struct WebInteractor: WhatsAppConversationInteractor {
    let accountId: UUID
    let accounts: () -> [WhatsAppWebAccount]
    let sessionStore: WhatsAppWebSessionStore
    let bridge: WhatsAppWebBridge

    func openConversation(_ conversation: ConversationSummary) async throws {
        // Intentionally inert until the Web selection interaction is restored.
        _ = conversation
    }
}
