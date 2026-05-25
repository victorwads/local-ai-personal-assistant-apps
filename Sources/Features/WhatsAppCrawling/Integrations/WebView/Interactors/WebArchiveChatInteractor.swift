import Foundation

struct WebArchiveChatInteractor: ArchiveChatInteractor {
    typealias Input = CrawledChat
    typealias Output = Void

    let runtime: WebViewRuntime
    let actionRegistry: WebActionRegistry

    func execute(_ input: CrawledChat) async -> CrawlingResult<Void> {
        .failure(.notImplemented("Web chat archiving is not wired yet."))
    }
}
