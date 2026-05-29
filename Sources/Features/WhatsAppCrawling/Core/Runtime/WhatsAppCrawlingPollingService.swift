import Foundation

@MainActor
final class WhatsAppCrawlingPollingService: ObservableObject, WhatsAppCrawlingService {
    private let profileId: String
    private let settings: WhatsAppCrawlingSettingsWrapper
    private weak var webViewService: WebViewWhatsAppCrawlingService?
    private let chatRepository: any ChatRepository
    private let orchestrator: WhatsAppChatCrawlingOrchestrator

    private var pollingTask: Task<Void, Never>?
    @Published private(set) var state: WhatsAppCrawlingServiceState = .stopped

    let activeIntegration: WhatsAppCrawlingActiveIntegration = .webView
    var integration: (any WhatsAppCrawlingIntegration)? { nil }

    init(
        profileId: String,
        settings: WhatsAppCrawlingSettingsWrapper,
        webViewService: WebViewWhatsAppCrawlingService,
        chatRepository: any ChatRepository
    ) throws {
        self.profileId = profileId
        self.settings = settings
        self.webViewService = webViewService
        self.chatRepository = chatRepository
        let yamlText = try WebYAMLSelectorLoader.loadBundledYAML()
        self.orchestrator = WhatsAppChatCrawlingOrchestrator(chatRepository: chatRepository, yamlText: yamlText)
    }

    func start() async {
        guard state == .stopped || isFailed else { return }
        state = .starting

        pollingTask = Task { [weak self] in
            guard let self else { return }
            await MainActor.run {
                state = .started
            }

            while !Task.isCancelled {
                await MainActor.run {
                    guard state == .started else { return }
                }

                if let webView = await MainActor.run(body: { self.webViewService?.webView }) {
                    _ = await orchestrator.runCycle(in: webView)
                }

                let intervalSeconds = await MainActor.run {
                    max(1, self.settings.pollingIntervalSeconds)
                }
                try? await Task.sleep(nanoseconds: UInt64(intervalSeconds) * 1_000_000_000)
            }
        }
    }

    func stop() async {
        guard state == .started || state == .starting || isFailed else { return }
        state = .stopping
        pollingTask?.cancel()
        pollingTask = nil
        state = .stopped
    }

    private var isFailed: Bool {
        if case .failed = state { return true }
        return false
    }
}
