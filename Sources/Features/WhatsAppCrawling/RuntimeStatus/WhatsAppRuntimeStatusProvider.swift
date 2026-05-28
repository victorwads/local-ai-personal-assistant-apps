import Foundation

@MainActor
struct WhatsAppRuntimeStatusProvider: ProfileRuntimeStatusProvider {
    let webViewService: any ProfileRuntimeService
    let crawlingService: any ProfileRuntimeService

    func statusItems() -> [ProfileRuntimeStatusItem] {
        [
            item(for: webViewService, id: "whatsapp.webview.status", title: "WebView"),
            item(for: crawlingService, id: "whatsapp.crawling.status", title: "Crawling")
        ]
    }

    private func item(
        for service: any ProfileRuntimeService,
        id: String,
        title: String
    ) -> ProfileRuntimeStatusItem {
        let actionTitle = ProfileRuntimeServiceStatusFormatting.actionTitle(for: service.state)
        return ProfileRuntimeStatusItem(
            id: id,
            title: title,
            stateLabel: ProfileRuntimeServiceStatusFormatting.stateLabel(for: service.state),
            detail: ProfileRuntimeServiceStatusFormatting.detail(for: service.state),
            actionTitle: actionTitle,
            action: actionTitle.map { _ in
                {
                    await performAction(for: service)
                }
            }
        )
    }

    private func performAction(for service: any ProfileRuntimeService) async {
        switch service.state {
        case .stopped, .failed:
            await service.start()
        case .running, .starting:
            await service.stop()
        case .stopping:
            break
        }
    }
}
