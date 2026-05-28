import SwiftUI

struct CommandCenterScreen: View {
    let profile: Profile
    let runtimeState: ProfileRuntimeState
    let windowState: ProfileWindowState
    let settingsSectionRegistry: SettingsSectionRegistry?
    let statusRegistry: ProfileRuntimeStatusRegistry?
    let whatsAppWebViewService: WebViewWhatsAppCrawlingService?

    @State private var selectedRoute: CommandCenterRoute? = .myProfile

    private let sections = CommandCenterMenuRegistry.sections()
    private let screenRegistry = CommandCenterScreenRegistry()

    var body: some View {
        NavigationSplitView {
            CommandCenterSidebar(
                sections: sections,
                selectedRoute: selectedRouteBinding
            )
        } detail: {
            VStack(spacing: 0) {
                CommandCenterHeaderView(
                    profile: profile,
                    runtimeState: runtimeState,
                    windowState: windowState,
                    statusRegistry: statusRegistry
                )

                Divider()

                CommandCenterContentView(
                    route: selectedRoute ?? .myProfile,
                    profile: profile,
                    runtimeState: runtimeState,
                    windowState: windowState,
                    settingsSectionRegistry: settingsSectionRegistry,
                    whatsAppWebViewService: whatsAppWebViewService,
                    screenRegistry: screenRegistry
                )
            }
            .frame(minWidth: 620, minHeight: 520)
        }
        .frame(minWidth: 900, minHeight: 560)
    }

    private var selectedRouteBinding: Binding<CommandCenterRoute> {
        Binding(
            get: { selectedRoute ?? .myProfile },
            set: { selectedRoute = $0 }
        )
    }
}
