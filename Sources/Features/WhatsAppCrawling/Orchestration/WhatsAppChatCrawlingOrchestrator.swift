import Foundation
import WebKit

@MainActor
final class WhatsAppChatCrawlingOrchestrator {
    private let chatRepository: any ChatRepository
    private let yamlText: String

    init(chatRepository: any ChatRepository, yamlText: String) {
        self.chatRepository = chatRepository
        self.yamlText = yamlText
    }

    func runCycle(in webView: WKWebView) async -> CrawlingResult<Void> {
        do {
            let extractionJSON = try await WebYAMLExtractionRunner.run(yamlText: yamlText, in: webView)
            guard let rootObject = parseJSONObject(from: extractionJSON) else {
                return .failure(.parsingFailed("Unable to parse extraction JSON."))
            }

            if shouldStopBecauseBlockedFlow(rootObject) {
                return .success(())
            }

            let headers = WhatsAppChatListParser.parse(from: rootObject)
            let interactor = WebViewElementInteractor(webView: webView)

            for header in headers {
                let existingChat = try await chatRepository.getChat(id: header.id)
                guard shouldRefreshChatMessages(header: header, existingChat: existingChat) else { continue }

                let observedAt = Date()
                let chat = Chat(
                    id: header.id,
                    title: header.title,
                    lastMessagePreview: header.lastMessagePreview,
                    lastMessageTimeText: header.lastMessageTimeText,
                    unreadCount: header.unreadCount,
                    stateHash: header.stateHash,
                    observedAt: observedAt,
                    createdAt: existingChat?.createdAt ?? observedAt,
                    updatedAt: observedAt,
                    deletedAt: nil
                )
                try await chatRepository.upsertChat(chat)

                if let openElement = header.openChatElement {
                    _ = try await interactor.click(openElement)
                    try? await Task.sleep(nanoseconds: 600_000_000)
                }

                let currentChatJSON = try await WebYAMLExtractionRunner.run(yamlText: yamlText, in: webView)
                guard let currentChatObject = parseJSONObject(from: currentChatJSON) else { continue }
                guard let parsedCurrentChat = WhatsAppCurrentChatParser.parse(from: currentChatObject, observedAt: observedAt) else { continue }
                guard parsedCurrentChat.chatId == header.id else { continue }

                let existingIds = try await chatRepository.existingMessageIds(chatId: header.id)
                let newMessages = parsedCurrentChat.messages.filter { message in
                    guard let id = message.id else { return false }
                    return !existingIds.contains(id)
                }
                try await chatRepository.upsertMessages(newMessages)
            }

            return .success(())
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func shouldRefreshChatMessages(header: ParsedChatHeader, existingChat: Chat?) -> Bool {
        guard let existingChat else { return true }
        if header.unreadCount > 0 { return true }
        if header.stateHash != existingChat.stateHash { return true }
        return false
    }

    private func shouldStopBecauseBlockedFlow(_ rootObject: [String: Any]) -> Bool {
        guard let flows = rootObject["flows"] as? [String: Any] else { return false }
        let loginQr = (flows["loginQr"] as? Bool) ?? false
        let downloading = (flows["downloading"] as? Bool) ?? false
        return loginQr || downloading
    }

    private func parseJSONObject(from text: String) -> [String: Any]? {
        guard let data = text.data(using: .utf8) else { return nil }
        guard let object = try? JSONSerialization.jsonObject(with: data) else { return nil }
        return object as? [String: Any]
    }
}
