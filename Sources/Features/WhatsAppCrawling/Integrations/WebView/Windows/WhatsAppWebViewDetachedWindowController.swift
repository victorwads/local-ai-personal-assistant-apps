import AppKit
import SwiftUI
import WebKit

@MainActor
final class WhatsAppWebViewDetachedWindowController: NSWindowController, NSWindowDelegate {
    private weak var service: WebViewWhatsAppCrawlingService?

    init(service: WebViewWhatsAppCrawlingService, webView: WKWebView) {
        self.service = service

        let hostingController = NSHostingController(
            rootView: WebViewContainerView(webView: webView)
        )
        let window = NSWindow(contentViewController: hostingController)
        window.title = "WhatsApp Web"
        window.setContentSize(NSSize(width: 980, height: 740))
        window.styleMask.insert(.closable)
        window.styleMask.insert(.resizable)
        window.isReleasedWhenClosed = false

        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func windowWillClose(_ notification: Notification) {
        service?.detachedWindowDidClose()
    }
}
