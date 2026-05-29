import Foundation

/// Profile-scoped runtime container for one profile.
///
/// The container can exist for UI/settings while profile services are stopped.
/// Starting services is an explicit lifecycle step.
@MainActor
final class ProfileRuntimeContainer {
    let context: ProfileContext
    let settings: SettingsStore
    let settingsSectionRegistry: SettingsSectionRegistry
    let aiConnectionSettings: AIConnectionSettingsWrapper
    let mcpServerSettings: MCPServerSettingsWrapper
    let whatsAppCrawlingSettings: WhatsAppCrawlingSettingsWrapper
    let whatsAppWebViewSettings: WhatsAppWebViewSettingsWrapper
    let whatsAppNativeSettings: WhatsAppNativeSettingsWrapper
    let whatsAppCrawlingLogStore: WhatsAppCrawlingLogStore
    let serviceRegistry: ProfileRuntimeServiceRegistry
    let statusRegistry: ProfileRuntimeStatusRegistry

    private(set) var whatsAppCrawlingService: (any WhatsAppCrawlingService)?
    private(set) var whatsAppWebViewService: WebViewWhatsAppCrawlingService?
    private var settingsStarted = false
    private var statusProvidersRegistered = false

    init(context: ProfileContext) throws {
        guard let scope = context.scope else {
            throw ProfileRuntimeContainerError.missingProfileScope
        }

        self.context = context
        self.settings = SettingsStore(scope: scope)
        self.aiConnectionSettings = AIConnectionSettingsWrapper(settings: settings)
        self.mcpServerSettings = MCPServerSettingsWrapper(settings: settings)
        self.whatsAppCrawlingSettings = WhatsAppCrawlingSettingsWrapper(settings: settings)
        self.whatsAppWebViewSettings = WhatsAppWebViewSettingsWrapper(settings: settings)
        self.whatsAppNativeSettings = WhatsAppNativeSettingsWrapper(settings: settings)
        self.whatsAppCrawlingLogStore = WhatsAppCrawlingLogStore()
        self.serviceRegistry = ProfileRuntimeServiceRegistry()
        self.statusRegistry = ProfileRuntimeStatusRegistry()
        self.settingsSectionRegistry = SettingsSectionRegistry()
        self.settingsSectionRegistry.register(
            WhatsAppCrawlingSettingsSectionProvider(
                crawlingSettings: whatsAppCrawlingSettings,
                webViewSettings: whatsAppWebViewSettings,
                nativeSettings: whatsAppNativeSettings
            )
        )
        self.settingsSectionRegistry.register(
            AIConnectionSettingsSectionProvider(wrapper: aiConnectionSettings)
        )
    }

    func startSettings() async throws {
        if !settingsStarted {
            try await settings.start()
            settingsStarted = true
        }
        try await registerConfiguredServices()
    }

    func startServices() async throws {
        try await startSettings()

        await serviceRegistry.startServices { [weak self] service in
            guard let self else { return false }
            return shouldAutoStart(service)
        }
    }

    func stopServices() async {
        await serviceRegistry.stopAll()
    }

    func stop() async {
        await stopServices()
        await settings.stop()
        settingsStarted = false
    }

    private func registerConfiguredServices() async throws {
        registerWhatsAppWebViewServiceIfNeeded()
        try registerWhatsAppCrawlingServiceIfNeeded()
        registerPlaceholderServiceIfNeeded(id: profileRuntimeAIConnectionServiceId, title: "AI Connection")
        registerPlaceholderServiceIfNeeded(id: profileRuntimeMCPServerServiceId, title: "MCP Server")
        registerStatusProvidersIfNeeded()
    }

    private func registerWhatsAppWebViewServiceIfNeeded() {
        guard serviceRegistry.service(id: profileRuntimeWhatsAppWebViewServiceId) == nil else { return }

        let service = WebViewWhatsAppCrawlingService(profileId: context.profileId, settings: whatsAppWebViewSettings)
        serviceRegistry.register(
            WhatsAppCrawlingProfileRuntimeService(
                id: profileRuntimeWhatsAppWebViewServiceId,
                title: "WhatsApp WebView",
                service: service
            )
        )
        whatsAppCrawlingService = service
        whatsAppWebViewService = service
    }

    private func registerPlaceholderServiceIfNeeded(id: String, title: String) {
        guard serviceRegistry.service(id: id) == nil else { return }
        serviceRegistry.register(PlaceholderProfileRuntimeService(id: id, title: title))
    }

    private func registerWhatsAppCrawlingServiceIfNeeded() throws {
        guard serviceRegistry.service(id: profileRuntimeWhatsAppCrawlingServiceId) == nil else { return }
        guard let webViewService = whatsAppWebViewService else { return }
        guard let scope = context.scope else { return }
        let chatRepository = FirestoreChatRepository(scope: scope)
        let service = try WhatsAppCrawlingPollingService(
            profileId: context.profileId,
            settings: whatsAppCrawlingSettings,
            webViewService: webViewService,
            chatRepository: chatRepository,
            logStore: whatsAppCrawlingLogStore
        )
        serviceRegistry.register(
            WhatsAppCrawlingProfileRuntimeService(
                id: profileRuntimeWhatsAppCrawlingServiceId,
                title: "WhatsApp Crawling/Polling",
                service: service
            )
        )
    }

    private func shouldAutoStart(_ service: any ProfileRuntimeService) -> Bool {
        switch service.id {
        case profileRuntimeWhatsAppWebViewServiceId:
            return whatsAppWebViewSettings.autoStart
        case profileRuntimeWhatsAppCrawlingServiceId:
            return whatsAppCrawlingSettings.autoStart
        case profileRuntimeAIConnectionServiceId:
            return aiConnectionSettings.autoStart
        case profileRuntimeMCPServerServiceId:
            return mcpServerSettings.autoStart
        default:
            return false
        }
    }

    private func registerStatusProvidersIfNeeded() {
        guard !statusProvidersRegistered else { return }

        if
            let webViewService = serviceRegistry.service(id: profileRuntimeWhatsAppWebViewServiceId),
            let crawlingService = serviceRegistry.service(id: profileRuntimeWhatsAppCrawlingServiceId)
        {
            statusRegistry.register(
                WhatsAppRuntimeStatusProvider(
                    webViewService: webViewService,
                    crawlingService: crawlingService
                )
            )
        }

        if let aiConnectionService = serviceRegistry.service(id: profileRuntimeAIConnectionServiceId) {
            statusRegistry.register(
                AIConnectionRuntimeStatusProvider(service: aiConnectionService)
            )
        }

        if let mcpServerService = serviceRegistry.service(id: profileRuntimeMCPServerServiceId) {
            statusRegistry.register(
                MCPServerRuntimeStatusProvider(
                    service: mcpServerService,
                    port: context.mcpPort
                )
            )
        }

        statusProvidersRegistered = true
    }
}

private let profileRuntimeWhatsAppWebViewServiceId = "whatsapp.webview"
private let profileRuntimeWhatsAppCrawlingServiceId = "whatsapp.crawling"
private let profileRuntimeAIConnectionServiceId = "ai.connection"
private let profileRuntimeMCPServerServiceId = "mcp.server"

private enum ProfileRuntimeContainerError: LocalizedError {
    case missingProfileScope

    var errorDescription: String? {
        switch self {
        case .missingProfileScope:
            return "Profile runtime cannot start without a persisted profile id."
        }
    }
}
