import Foundation

struct WebFlowParser: FlowParser {
    typealias Input = ParserContext<WebFlowRegistry, WebViewRuntime>
    typealias Output = FlowState

    let registry: WebFlowRegistry
    let runtime: WebViewRuntime

    func parse(_ input: Input) async -> CrawlingResult<FlowState> {
        .failure(.notImplemented("Web flow detection is not wired yet."))
    }
}
