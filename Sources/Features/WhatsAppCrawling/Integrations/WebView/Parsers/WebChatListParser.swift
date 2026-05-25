import Foundation

struct WebChatListParser: ChatListParser {
    typealias Input = WebParserContext
    typealias Output = [CrawledChat]

    let registry: WebExtractionRegistry
    let runtime: WebViewRuntime

    func parse(_ input: WebParserContext) async -> CrawlingResult<[CrawledChat]> {
        .failure(.notImplemented("Web chat list parsing is not wired yet."))
    }
}
