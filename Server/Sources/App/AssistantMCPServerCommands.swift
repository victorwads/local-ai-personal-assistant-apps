import SwiftUI

struct AssistantMCPServerCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Show Profiles Window") {
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "profiles" }) {
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                } else {
                    openWindow(id: "profiles")
                }
            }
        }

        CommandGroup(after: .windowList) {
            Button("Show All Managed Windows") {
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "profiles" }) {
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                } else {
                    openWindow(id: "profiles")
                }
                ProfileWindowManager.shared.showAllManagedWindows()
            }
        }
    }
}
