import Foundation

struct WebMessageListParser: MessageListParser {
    typealias Input = WebParserContext
    typealias Output = [CrawledMessage]

    let registry: WebExtractionRegistry
    let runtime: WebViewRuntime

    func parse(_ input: WebParserContext) async -> CrawlingResult<[CrawledMessage]> {
        .failure(.notImplemented("Web message list parsing is not wired yet."))
    }
}
