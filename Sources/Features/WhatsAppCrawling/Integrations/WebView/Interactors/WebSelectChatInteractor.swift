import Foundation

struct WebSelectChatInteractor: SelectChatInteractor {
    typealias Input = CrawledChat
    typealias Output = Void

    let runtime: WebViewRuntime
    let actionRegistry: WebActionRegistry

    func execute(_ input: CrawledChat) async -> CrawlingResult<Void> {
        .failure(.notImplemented("Web chat selection is not wired yet."))
    }
}
