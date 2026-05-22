import SwiftUI

@main
@MainActor
struct AssistantMCPServerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("Profiles", id: "profiles") {
            RootView()
        }
        .windowStyle(.titleBar)
        .commands {
            AssistantMCPServerCommands()
        }
    }
}
