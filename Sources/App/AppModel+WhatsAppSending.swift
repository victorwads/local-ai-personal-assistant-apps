import Foundation

extension AppModel {
    func sendWhatsAppMessagesViaCurrentIntegration(_ texts: [String], to conversationId: String) async throws {
        let trimmedTexts = texts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !trimmedTexts.isEmpty else {
            throw MCPServerError.invalidParameter("messages")
        }

        switch whatsAppIntegrationSettings.mode {
        case .desktopAX:
            try await whatsappMessageSendCoordinator.sendMessagesViaScheduler(trimmedTexts, to: conversationId)

        case .web:
            try await sendWhatsAppWebMessages(trimmedTexts, to: conversationId)
        }
    }

    func sendWhatsAppMessageViaCurrentIntegration(_ text: String, to conversationId: String) async throws {
        try await sendWhatsAppMessagesViaCurrentIntegration([text], to: conversationId)
    }

    private func sendWhatsAppWebMessages(_ texts: [String], to conversationId: String) async throws {
        guard let conversation = memoryStore.conversation(for: conversationId) else {
            throw MCPServerError.invalidParameter("chatId")
        }
        guard let account = selectedWhatsAppWebAccount else {
            throw MCPServerError.invalidParameter("whatsappWebAccount")
        }

        let provider = WebProvider(
            accountId: account.id,
            accounts: { [weak self] in self?.whatsAppWebAccounts ?? [] },
            sessionStore: whatsAppWebSessionStore,
            bridge: whatsAppWebBridge,
            messageSettleDelayMilliseconds: whatsAppWebSettings.messageSettleDelayMilliseconds
        )

        let webView = whatsAppWebSessionStore.webView(for: account)
        for text in texts {
            try await provider.interactor.openConversation(conversation)

            let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalizedText.isEmpty else {
                continue
            }

            let beforeCapture = try await whatsAppWebBridge.captureSelectedChat(from: webView, limit: 50)
            let beforeCount = beforeCapture.messages.count

            let sendResult = try await whatsAppWebBridge.sendMessage(from: webView, text: normalizedText)
            guard sendResult.composerFound, sendResult.inserted, sendResult.currentText == normalizedText else {
                throw WhatsAppWebBridgeError.elementNotFound(
                    "sendMessage(title='\(conversation.name)') composerFound=\(sendResult.composerFound) inserted=\(sendResult.inserted) currentText=\(sendResult.currentText ?? "nil")"
                )
            }

            try await Task.sleep(for: .milliseconds(300))

            let afterCapture = try await whatsAppWebBridge.captureSelectedChat(from: webView, limit: 50)
            let afterLastMessage = afterCapture.messages.last
            let afterLastText = afterLastMessage?.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let afterCount = afterCapture.messages.count

            let didAppendMessage = afterCount > beforeCount || afterLastText == normalizedText
            guard didAppendMessage else {
                throw WhatsAppWebBridgeError.elementNotFound(
                    "sendMessage(title='\(conversation.name)') did not observe the outgoing message after Enter. beforeCount=\(beforeCount) afterCount=\(afterCount) afterLastText=\(afterLastText ?? "nil")"
                )
            }
        }

        await forceUpdateSelectedWhatsAppWebChat(for: account)
    }
}
