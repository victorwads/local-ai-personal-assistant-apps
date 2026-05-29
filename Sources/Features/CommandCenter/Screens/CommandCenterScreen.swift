import SwiftUI
import AppKit

struct CommandCenterScreen: View {
    let profile: Profile
    let runtimeState: ProfileRuntimeState
    let windowState: ProfileWindowState
    let settingsSectionRegistry: SettingsSectionRegistry?
    let statusRegistry: ProfileRuntimeStatusRegistry?
    @ObservedObject var whatsAppWebViewService: WebViewWhatsAppCrawlingService
    let whatsAppCrawlingLogStore: WhatsAppCrawlingLogStore

    @State private var selectedRoute: CommandCenterRoute? = .myProfile

    private let screenRegistry = CommandCenterScreenRegistry()

    var body: some View {
        NavigationSplitView {
            CommandCenterSidebar(
                sections: sections,
                whatsAppWebViewService: whatsAppWebViewService,
                onDetachWebView: detachWebViewFromSidebar,
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
                    whatsAppCrawlingLogStore: whatsAppCrawlingLogStore,
                    screenRegistry: screenRegistry
                )
            }
            .frame(minWidth: 620, minHeight: 520)
        }
        .frame(minWidth: 900, minHeight: 560)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    toggleSidebar()
                } label: {
                    Image(systemName: "sidebar.leading")
                }
                .help("Toggle Sidebar")
            }
        }
        .onChange(of: whatsAppWebViewService.presentationMode) { mode in
            guard mode == .detached else { return }
            if selectedRoute == .whatsappWebView {
                selectedRoute = .myProfile
            }
        }
    }

    private var selectedRouteBinding: Binding<CommandCenterRoute> {
        Binding(
            get: { selectedRoute ?? .myProfile },
            set: { selectedRoute = $0 }
        )
    }

    private var sections: [CommandCenterSection] {
        CommandCenterMenuRegistry.sections(
            isWhatsAppWebViewVisible: whatsAppWebViewService.presentationMode == .embedded
        )
    }

    private func detachWebViewFromSidebar() {
        whatsAppWebViewService.detach()
        if selectedRoute == .whatsappWebView {
            selectedRoute = .myProfile
        }
    }

    private func toggleSidebar() {
        NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
    }
}
