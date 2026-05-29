import SwiftUI

struct CommandCenterContentView: View {
    let route: CommandCenterRoute
    let profile: Profile
    let runtimeState: ProfileRuntimeState
    let windowState: ProfileWindowState
    let settingsSectionRegistry: SettingsSectionRegistry?
    let whatsAppWebViewService: WebViewWhatsAppCrawlingService?
    let whatsAppCrawlingLogStore: WhatsAppCrawlingLogStore
    let screenRegistry: CommandCenterScreenRegistry

    var body: some View {
        screenRegistry.screen(
            for: route,
            profile: profile,
            runtimeState: runtimeState,
            windowState: windowState,
            settingsSectionRegistry: settingsSectionRegistry,
            whatsAppWebViewService: whatsAppWebViewService,
            whatsAppCrawlingLogStore: whatsAppCrawlingLogStore
        )
    }
}
