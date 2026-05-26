import Foundation

enum WhatsAppIntegrationOperation: String, CaseIterable, Sendable {
    case listChats
    case selectChat
    case listChatMessages
    case sendMessage
    case archiveChat
}

struct WhatsAppIntegrationContext: Sendable, Equatable {
    let mode: WhatsAppIntegrationMode
    let flow: String?
    let extractionTree: AnySendable?

    init(
        mode: WhatsAppIntegrationMode,
        flow: String? = nil,
        extractionTree: AnySendable? = nil
    ) {
        self.mode = mode
        self.flow = flow
        self.extractionTree = extractionTree
    }
}

struct WhatsAppMessagesParseResult: Sendable, Equatable {
    let selectedChatName: String?
    let flow: String?
    let messages: [Message]
    let composeFocused: Bool
    let canSendText: Bool
}

struct WhatsAppSendMessageRequest: Sendable, Equatable {
    let chatId: String
    let texts: [String]
}

struct WhatsAppSendMessageResult: Sendable, Equatable {
    let chatId: String
    let sentTexts: [String]
}

@MainActor
protocol WhatsAppIntegrationOperationHandler {
    var operation: WhatsAppIntegrationOperation { get }
    func verify(context: WhatsAppIntegrationContext) throws
}

@MainActor
protocol WhatsAppIntegrationParser: WhatsAppIntegrationOperationHandler {}

@MainActor
protocol WhatsAppIntegrationInteractor: WhatsAppIntegrationOperationHandler {}

@MainActor
protocol WhatsAppChatListParser: WhatsAppIntegrationParser {
    func parse(context: WhatsAppIntegrationContext) throws -> [ConversationSummary]
}

@MainActor
protocol WhatsAppChatMessagesParser: WhatsAppIntegrationParser {
    func parseMessages(context: WhatsAppIntegrationContext, limit: Int) throws -> WhatsAppMessagesParseResult
}

@MainActor
protocol WhatsAppChatSelectionInteractor: WhatsAppIntegrationInteractor {
    func act(context: WhatsAppIntegrationContext, conversation: ConversationSummary) async throws
}

@MainActor
protocol WhatsAppSendMessageInteractor: WhatsAppIntegrationInteractor {
    func act(context: WhatsAppIntegrationContext, request: WhatsAppSendMessageRequest) async throws -> WhatsAppSendMessageResult
}

@MainActor
protocol WhatsAppArchiveChatInteractor: WhatsAppIntegrationInteractor {
    func act(context: WhatsAppIntegrationContext, conversation: ConversationSummary?) async throws
}

extension WhatsAppChatListParser {
    var operation: WhatsAppIntegrationOperation { .listChats }
}

extension WhatsAppChatSelectionInteractor {
    var operation: WhatsAppIntegrationOperation { .selectChat }
}

extension WhatsAppChatMessagesParser {
    var operation: WhatsAppIntegrationOperation { .listChatMessages }
}

extension WhatsAppSendMessageInteractor {
    var operation: WhatsAppIntegrationOperation { .sendMessage }
}

extension WhatsAppArchiveChatInteractor {
    var operation: WhatsAppIntegrationOperation { .archiveChat }
}

@MainActor
protocol WhatsAppConversationInteractor {
    func openConversation(_ conversation: ConversationSummary) async throws
}

@MainActor
protocol WhatsAppConversationParser {
    func listConversations() async throws -> [ConversationSummary]
    func readMessages(limit: Int) async throws -> (selectedChatName: String?, flow: String?, messages: [Message], composeFocused: Bool, canSendText: Bool)
}

@MainActor
protocol WhatsAppIntegrationProvider {
    var kind: WhatsAppIntegrationMode { get }
    var parser: WhatsAppConversationParser { get }
    var interactor: WhatsAppConversationInteractor { get }
}
