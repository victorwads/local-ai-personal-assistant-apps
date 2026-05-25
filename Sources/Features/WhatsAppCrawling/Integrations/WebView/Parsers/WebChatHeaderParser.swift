import Foundation

struct WebChatHeaderParser: ChatHeaderParser {
    typealias Input = WebParserContext
    typealias Output = CrawledChatHeader

    let registry: WebExtractionRegistry
    let runtime: WebViewRuntime

    func parse(_ input: WebParserContext) async -> CrawlingResult<CrawledChatHeader> {
        .failure(.notImplemented("Web chat header parsing is not wired yet."))
    }
}
