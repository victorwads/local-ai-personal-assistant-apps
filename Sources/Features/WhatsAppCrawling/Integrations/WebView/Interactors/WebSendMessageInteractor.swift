import Foundation

struct WebSendMessageInteractor: SendMessageInteractor {
    typealias Input = SendMessageInput
    typealias Output = Void

    let runtime: WebViewRuntime
    let actionRegistry: WebActionRegistry

    func execute(_ input: SendMessageInput) async -> CrawlingResult<Void> {
        .failure(.notImplemented("Web message sending is not wired yet."))
    }
}
