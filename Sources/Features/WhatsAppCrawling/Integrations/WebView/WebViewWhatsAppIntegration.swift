import Foundation

final class WebViewWhatsAppIntegration: WhatsAppCrawlingIntegration {
    private let config: CrawlingConfig
    private let runtime: WebViewRuntime
    private let actionRegistry: WebActionRegistry
    private let flowRegistry: WebFlowRegistry
    private let extractionRegistry: WebExtractionRegistry

    init(
        config: CrawlingConfig,
        runtime: WebViewRuntime,
        configMapper: WebConfigMapper = WebConfigMapper()
    ) {
        self.config = config
        self.runtime = runtime
        self.actionRegistry = configMapper.makeActionRegistry(from: config)
        self.flowRegistry = configMapper.makeFlowRegistry(from: config)
        self.extractionRegistry = configMapper.makeExtractionRegistry(from: config)
    }

    func resolveFlowState() async -> CrawlingResult<FlowState> {
        let parser = WebFlowParser(registry: flowRegistry, runtime: runtime)
        return await parser.parse(ParserContext(config: flowRegistry, flowState: FlowState(activeFlowIdentifiers: []), runtime: runtime))
    }

    func listChats() async -> CrawlingResult<[CrawledChat]> {
        let parser = WebChatListParser(registry: extractionRegistry, runtime: runtime)
        return await parser.parse(ParserContext(config: extractionRegistry, flowState: FlowState(activeFlowIdentifiers: []), runtime: runtime))
    }

    func selectChat(_ chat: CrawledChat) async -> CrawlingResult<Void> {
        let interactor = WebSelectChatInteractor(runtime: runtime, actionRegistry: actionRegistry)
        return await interactor.execute(chat)
    }

    func listMessages() async -> CrawlingResult<[CrawledMessage]> {
        let parser = WebMessageListParser(registry: extractionRegistry, runtime: runtime)
        return await parser.parse(ParserContext(config: extractionRegistry, flowState: FlowState(activeFlowIdentifiers: []), runtime: runtime))
    }

    func sendMessage(_ input: SendMessageInput) async -> CrawlingResult<Void> {
        let interactor = WebSendMessageInteractor(runtime: runtime, actionRegistry: actionRegistry)
        return await interactor.execute(input)
    }

    func archiveChat(_ chat: CrawledChat) async -> CrawlingResult<Void> {
        let interactor = WebArchiveChatInteractor(runtime: runtime, actionRegistry: actionRegistry)
        return await interactor.execute(chat)
    }
}
