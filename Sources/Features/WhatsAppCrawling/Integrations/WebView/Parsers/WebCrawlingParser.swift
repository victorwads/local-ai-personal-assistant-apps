import Foundation

typealias WebParserContext = ParserContext<WebExtractionRegistry, WebViewRuntime>

struct WebCrawlingParser: CrawlingParser {
    typealias Input = WebParserContext
    typealias Output = ExtractedTree

    let registry: WebExtractionRegistry
    let runtime: WebViewRuntime

    func parse(_ input: WebParserContext) async -> CrawlingResult<ExtractedTree> {
        .failure(.notImplemented("Web extraction parsing is not wired yet."))
    }
}
