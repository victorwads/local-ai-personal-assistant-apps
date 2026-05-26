import SwiftUI

struct ServerLogsPlaceholderScreen: View {
    var body: some View {
        CommandCenterPlaceholderScreen(
            title: "Server Logs",
            description: "MCP server calls, runtime events, and diagnostic logs will appear here."
        )
    }
}
