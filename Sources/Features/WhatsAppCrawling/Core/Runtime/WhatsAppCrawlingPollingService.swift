import Foundation

@MainActor
final class WhatsAppCrawlingPollingService: ObservableObject, WhatsAppCrawlingService {
    private let profileId: String
    private let settings: WhatsAppCrawlingSettingsWrapper
    private weak var webViewService: WebViewWhatsAppCrawlingService?
    private let chatRepository: any ChatRepository
    private let logStore: WhatsAppCrawlingLogStore
    private let orchestrator: WhatsAppChatCrawlingOrchestrator

    private var pollingTask: Task<Void, Never>?
    @Published private(set) var state: WhatsAppCrawlingServiceState = .stopped
    @Published private(set) var statusText: String? = "Stopped"

    let activeIntegration: WhatsAppCrawlingActiveIntegration = .webView
    var integration: (any WhatsAppCrawlingIntegration)? { nil }

    init(
        profileId: String,
        settings: WhatsAppCrawlingSettingsWrapper,
        webViewService: WebViewWhatsAppCrawlingService,
        chatRepository: any ChatRepository,
        logStore: WhatsAppCrawlingLogStore
    ) throws {
        self.profileId = profileId
        self.settings = settings
        self.webViewService = webViewService
        self.chatRepository = chatRepository
        self.logStore = logStore
        let yamlText = try WebYAMLSelectorLoader.loadBundledYAML()
        self.orchestrator = WhatsAppChatCrawlingOrchestrator(
            chatRepository: chatRepository,
            yamlText: yamlText,
            logStore: logStore
        )
    }

    func start() async {
        guard state == .stopped || isFailed else { return }
        state = .starting
        statusText = "Starting"
        logStore.append(source: "Polling", "Started profile=\(profileId)")
        logStore.append(source: "Polling", "Auto-start/manual start reached")
        orchestrator.setStatusUpdateHandler { [weak self] status in
            Task { @MainActor [weak self] in
                self?.statusText = status
            }
        }

        pollingTask = Task { [weak self] in
            guard let self else { return }
            await MainActor.run {
                self.state = .started
                self.statusText = "Started"
            }

            while !Task.isCancelled {
                await MainActor.run {
                    guard self.state == .started else { return }
                }

                if let webView = await MainActor.run(body: { self.webViewService?.webView }) {
                    await MainActor.run { self.statusText = "Starting cycle" }
                    await MainActor.run {
                        self.logStore.append(source: "Polling", "WebView available")
                        self.logStore.append(source: "Polling", "Cycle started")
                    }
                    let result = await orchestrator.runCycle(in: webView)
                    switch result {
                    case .success:
                        await MainActor.run { self.statusText = "Cycle finished" }
                        await MainActor.run {
                            self.logStore.append(source: "Polling", "Cycle success")
                        }
                    case .failure(let error):
                        await MainActor.run { self.statusText = "Failed: \(error.localizedDescription)" }
                        await MainActor.run {
                            self.logStore.append(source: "Error", "Cycle failed: \(error.localizedDescription)")
                        }
                    }
                } else {
                    await MainActor.run { self.statusText = "Waiting for WebView" }
                    await MainActor.run {
                        self.logStore.append(source: "Polling", "Waiting for WebView")
                    }
                }

                let intervalSeconds = await MainActor.run {
                    max(1, self.settings.pollingIntervalSeconds)
                }
                await MainActor.run { self.statusText = "Sleeping \(intervalSeconds)s" }
                await MainActor.run {
                    self.logStore.append(source: "Polling", "Sleeping \(intervalSeconds)s")
                }
                try? await Task.sleep(nanoseconds: UInt64(intervalSeconds) * 1_000_000_000)
            }
            await MainActor.run { self.statusText = "Stopped" }
            await MainActor.run {
                self.logStore.append(source: "Polling", "Stopped/cancelled")
            }
        }
    }

    func stop() async {
        guard state == .started || state == .starting || isFailed else { return }
        state = .stopping
        pollingTask?.cancel()
        pollingTask = nil
        state = .stopped
        statusText = "Stopped"
        logStore.append(source: "Polling", "Stopped")
    }

    private var isFailed: Bool {
        if case .failed = state { return true }
        return false
    }
}
