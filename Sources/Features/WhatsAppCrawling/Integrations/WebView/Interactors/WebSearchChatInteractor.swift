import Foundation

struct WebSearchChatInteractor: SearchChatInteractor {
    typealias Input = String
    typealias Output = Void

    let runtime: WebViewRuntime
    let actionRegistry: WebActionRegistry

    func execute(_ input: String) async -> CrawlingResult<Void> {
        .failure(.notImplemented("Web chat search is not wired yet."))
    }
}
